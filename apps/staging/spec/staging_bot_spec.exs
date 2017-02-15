defmodule Staging.BotSpec do
  use ESpec, async: false

  import CustomAssertions

  alias Staging.Factory
  alias Staging.Bot

  @slack_client Application.get_env(:staging, :slack_client)
  @slack_send Application.get_env(:staging, :slack_send)
  @bot_name "Tucker"
  @channel "C1234ABCD"
  @jim_smith_id "UXYZA1234"
  @message_user %{id: "UABCD1234", name: "sally", real_name: "Sally Jones"}

  @slack %{
    me: %{id: "U1234ABCD", name: @bot_name},
    users: %{
      @jim_smith_id => %{real_name: "Jim Smith"},
      @message_user.id => @message_user
    }
  }

  before do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Staging.Repo)

    @slack_client.set_slack(@slack)
    @slack_send.start_link
  end

  finally do
    @slack_send.clear!
    :ok = Ecto.Adapters.SQL.Sandbox.checkin(Staging.Repo)
  end

  describe "listing known servers" do
    context "there are no known servers" do
      it "says there are no known servers" do
        Bot.handle_event(%{type: "message", text: "#{@bot_name} list", channel: @channel, user: @message_user.id}, @slack, [])

        expect(@slack_send).to have_received([string_matching(~r/I don't know any servers/), @channel, @slack])
      end
    end

    context "there are servers" do
      let :reservation_end, do: Timex.shift(Staging.today, days: 3)

      before do
        non_prod = Factory.insert(:server, %{name: "non-prod-staging", prod_data: false})
        Factory.insert(:server, %{name: "prod-staging", prod_data: true})

        Factory.insert(:reservation, %{server: non_prod, user_id: @jim_smith_id, end_date: Ecto.Date.cast!(reservation_end)})
      end

      it "lists the servers" do
        Bot.handle_event(%{type: "message", text: "#{@bot_name} list", channel: @channel, user: @message_user.id}, @slack, [])

        reservation_end_str = Timex.format!(reservation_end, "%-m/%-d", :strftime)
        response = string_matching(~r/non-prod-staging.*Reserved by Jim Smith until #{reservation_end_str}\n. prod-staging \(w\/ Prod Data\)/iu)

        expect(@slack_send).to have_received([response, @channel, @slack])
      end
    end
  end

  describe "adding a server" do
    context "the server doesn't already exist" do
      it "adds the server" do
        Bot.handle_event(%{type: "message", text: "#{@bot_name} add server-1", channel: @channel, user: @message_user.id}, @slack, [])

        response = string_matching(~r/added server "server-1"/i)
        expect(@slack_send).to have_received([response, @channel, @slack])
        expect(Staging.Repo.exists?(Staging.Server, name: "server-1")).to be_true
      end
    end

    context "the server already exists" do
      before do
        Factory.insert(:server, %{name: "server-2"})
      end

      it "does not add the server" do
        Bot.handle_event(%{type: "message", text: "#{@bot_name} add server-2", channel: @channel, user: @message_user.id}, @slack, [])

        response = string_matching(~r/.*server already exists/i)
        expect(@slack_send).to have_received([response, @channel, @slack])
        expect(Staging.Repo.aggregate(Staging.Server, :count, :id)).to eq(1)
      end
    end
  end

  describe "reserving a server" do
    context "a server is available" do
      let :reservation_end, do: Timex.shift(Staging.today, days: 3)
      let :reservation_end_str, do: Timex.format!(reservation_end, "%Y-%m-%d", :strftime)
      let :reservation_end_str_short, do: Timex.format!(reservation_end, "%-m/%-d", :strftime)

      before do
        Factory.insert(:server, %{name: "server-1"})
      end

      it "creates a reservation" do
        Bot.handle_event(%{type: "message", text: "#{@bot_name} reserve until #{reservation_end_str}", channel: @channel, user: @message_user.id}, @slack, [])

        response = string_matching(~r/.*you have server-1 reserved until #{reservation_end_str_short}/i)
        expect(@slack_send).to have_received([response, @channel, @slack])

        active_reservation = Staging.Repo.get_by(Staging.Server.with_active_reservation, name: "server-1").active_reservation
        expect(active_reservation.user_id).to eq(@message_user.id)
        expect(Ecto.Date.to_erl(active_reservation.end_date)).to eq(Date.to_erl(reservation_end))
      end

      context "a specific server is requested" do
        before do
          Factory.insert(:server, %{name: "server-2"})
        end

        it "creates the requested reservation" do
          Bot.handle_event(%{type: "message", text: "#{@bot_name} reserve server-2 until #{reservation_end_str}", channel: @channel, user: @message_user.id}, @slack, [])

          response = string_matching(~r/.*you have server-2 reserved until #{reservation_end_str_short}/i)
          expect(@slack_send).to have_received([response, @channel, @slack])

          active_reservation = Staging.Repo.get_by(Staging.Server.with_active_reservation, name: "server-2").active_reservation
          expect(active_reservation.user_id).to eq(@message_user.id)
          expect(Ecto.Date.to_erl(active_reservation.end_date)).to eq(Date.to_erl(reservation_end))
        end
      end
    end

    context "a server is not available" do
      let :reservation_end, do: Timex.shift(Staging.today, days: 3)

      before do
        server = Factory.insert(:server, %{name: "server-1"})

        reservation = Factory.insert(:reservation, %{server: server, user_id: @jim_smith_id, end_date: Ecto.Date.cast!(Staging.today)})

        {:shared, reservation: reservation}
      end

      it "does not create a reservation" do
        reservation_end_str = Timex.format!(reservation_end, "%Y-%m-%d", :strftime)

        Bot.handle_event(%{type: "message", text: "#{@bot_name} reserve until #{reservation_end_str}", channel: @channel, user: @message_user.id}, @slack, [])

        response = string_matching(~r/.*there are no servers available/i)
        expect(@slack_send).to have_received([response, @channel, @slack])

        expect(Staging.Repo.pluck(Staging.Reservation, :id)).to eq([shared.reservation.id])
      end
    end
  end

  describe "releasing a reservation" do
    let :reservation_end, do: Timex.shift(Staging.today, days: 3)
    let :server, do: Factory.insert(:server, %{name: "server-1"})

    before do
      Factory.insert(:reservation, %{server: server, user_id: @message_user.id, end_date: Ecto.Date.cast!(reservation_end)})
    end

    it "makes the server available" do
      expect(Staging.Server.available?(server)).to be_false

      Bot.handle_event(
        %{
          type: "message",
          text: "#{@bot_name} release server-1",
          channel: @channel,
          user: @message_user.id
        },
        @slack, []
      )

      expect(Staging.Server.available?(server)).to be_true
    end
  end

  describe "updating prod data on a server" do
    before do
      Factory.insert(:server, %{name: "server-1"})
    end

    it "updates the server" do
      Bot.handle_event(%{type: "message", text: "#{@bot_name} set prod to true on server-1", channel: @channel, user: @message_user.id}, @slack, [])

      response = string_matching(~r/server-1 now has prod true/i)
      expect(@slack_send).to have_received([response, @channel, @slack])

      expect(Staging.Repo.one!(Staging.Server).prod_data).to be_true
    end
  end

  describe "responding to the bot's name" do
    it "only responds if the name is at the beginning of the message" do
      Bot.handle_event(%{type: "message", text: "Hi #{@bot_name} list", channel: @channel, user: @message_user.id}, @slack, [])

      expect(@slack_send.messages).to be_empty
    end
  end
end
