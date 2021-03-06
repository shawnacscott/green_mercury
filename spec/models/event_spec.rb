require 'spec_helper'

describe Event do
  
  it { should respond_to :title }
  it { should respond_to :description }
  it { should respond_to :location }
  it { should respond_to :start_time }
  it { should respond_to :end_time }

  it { should have_many(:event_rsvps).dependent(:destroy) }
  
  it { should validate_presence_of :title }
  it { should ensure_length_of(:title).is_at_most(100) }
  it { should validate_presence_of :description }
  it { should validate_presence_of :location }
  it { should ensure_length_of(:location).is_at_most(200) }
  it { should validate_presence_of :start_time }
  it { should validate_presence_of :end_time }

  it 'validates the start time is not in the past' do
    event = FactoryGirl.build(:event, start_time: Time.now - 1.day)
    expect(event.save).to be_false
  end

  it 'validates the end time is after the start time' do
    event = FactoryGirl.build(:event, start_time: Time.now + 2.day, end_time: Time.now + 1.day)
    expect(event.save).to be_false
  end

  describe '#rsvp' do 
    it 'rsvps the user to the event' do 
      event = FactoryGirl.create(:event)
      user = FactoryGirl.build(:user)
      event.rsvp(user)
      expect(event.rsvp?(user)).to be_true
    end
  end

  describe '#rsvp?' do
    it 'is true if the user has RSVPd to the event' do
      event = FactoryGirl.create(:event)
      user = FactoryGirl.build(:user)
      event.event_rsvps.create(user_uuid: user.uuid)
      expect(event.rsvp?(user)).to be_true
    end

    it 'is false if the user has not RSVPd to the event' do
      event = FactoryGirl.create(:event)
      user = FactoryGirl.build(:user)
      expect(event.rsvp?(user)).to be_false
    end
  end

  describe '#rsvp_for' do
    context 'when the user has RSVPd to the event' do 
      it 'gets the RSVP' do 
        event = FactoryGirl.create(:event)
        user = FactoryGirl.build(:user)
        event_rsvp = event.rsvp(user)
        expect(event.rsvp_for(user)).to eq event_rsvp
      end
    end

    context 'when the user has not RSVPd to the event' do 
      it 'is nil' do 
        event = FactoryGirl.create(:event)
        user = FactoryGirl.build(:user)
        expect(event.rsvp_for(user)).to be_nil
      end
    end
  end

  describe '#users_hash' do
    it 'is a hash of uuids and user objects for users attending the event' do
      event = FactoryGirl.create(:event)
      user = FactoryGirl.build(:user)
      event.rsvp(user)
      User.should_receive(:fetch_from_uuids).with([user.uuid])
      event.users_hash
    end
  end

  describe '#organizers_hash' do
    it 'is a hash of uuids and users for the event organizers' do
      event = FactoryGirl.create(:event)
      user = FactoryGirl.build(:user)
      event.event_rsvps.create(user_uuid: user.uuid, organizer: true)
      User.should_receive(:fetch_from_uuids).with([user.uuid])
      event.organizers_hash
    end
  end

  describe '#attendees_hash' do
    it 'is a hash of users that are not event organizers' do
      event = FactoryGirl.create(:event)
      user = FactoryGirl.build(:user)
      event.rsvp(user)
      User.should_receive(:fetch_from_uuids).with([user.uuid])
      event.attendees_hash
    end

    it 'does not get event organizers' do 
      event = FactoryGirl.create(:event)
      user = FactoryGirl.build(:user)
      event.event_rsvps.create(user_uuid: user.uuid, organizer: true)
      User.should_receive(:fetch_from_uuids).with([])
      event.attendees_hash
    end
  end

  describe '.upcoming_events' do
    it 'gets events that start after the current time' do
      event = FactoryGirl.create(:event, start_time: Time.now + 1.hour, end_time: Time.now + 1.day)
      expect(Event.upcoming_events).to match_array [event]
    end

    it 'does not get events that happened before the current time' do
      past_time = Time.now - 1.month
      Timecop.travel(past_time) 
      event = FactoryGirl.create(:event, start_time: past_time + 1.day, end_time: past_time + 2.days)
      Timecop.return
      expect(Event.upcoming_events).to_not include(event)
    end
  end

  describe '#organizer?' do
    context "when the user has an RSVP marked as an organizer" do 
      it "is true" do 
        user = FactoryGirl.build(:user)
        event = FactoryGirl.create(:event)
        event.event_rsvps.create(user_uuid: user.uuid, organizer: true)
        expect(event.organizer?(user)).to be_true
      end
    end

    context "when they have an RSVP not marked as an organizer" do 
      it "is false" do 
        user = FactoryGirl.build(:user)
        event = FactoryGirl.create(:event)
        event.event_rsvps.create(user_uuid: user.uuid, organizer: false)
        expect(event.organizer?(user)).to be_false
      end
    end

    context "when they have not RSVP to the event" do 
      it "is false" do 
        user = FactoryGirl.build(:user)
        event = FactoryGirl.create(:event)
        expect(event.organizer?(user)).to be_false
      end
    end
  end

  describe '#make_organizer' do 
    context 'when the user has an RSVP' do 
      it "makes them an organizer" do 
        user = FactoryGirl.build(:user)
        event = FactoryGirl.create(:event)
        event.rsvp(user)
        event.make_organizer(user)
        expect(event.organizer?(user)).to be_true
      end
    end
  end

  describe '#make_organizer_by_uuid' do 
    context 'when the user has an RSVP' do 
      it 'makes them an organizer' do 
        user = FactoryGirl.build(:user)
        event = FactoryGirl.create(:event)
        event.rsvp(user)
        event.make_organizer_by_uuid(user.uuid)
        expect(event.organizer?(user)).to be_true
      end
    end
  end
end







