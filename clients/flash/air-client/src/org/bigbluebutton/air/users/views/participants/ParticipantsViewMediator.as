package org.bigbluebutton.air.users.views.participants {
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.core.FlexGlobals;
	import mx.events.ResizeEvent;
	import mx.resources.ResourceManager;
	
	import org.bigbluebutton.air.common.views.PagesENUM;
	import org.bigbluebutton.air.common.views.SplitViewEvent;
	import org.bigbluebutton.air.common.views.TransitionAnimationENUM;
	import org.bigbluebutton.air.main.models.IUserUISession;
	import org.bigbluebutton.air.users.views.participants.guests.GuestResponseEvent;
	import org.bigbluebutton.lib.main.models.IUserSession;
	import org.bigbluebutton.lib.user.models.User;
	import org.bigbluebutton.lib.user.services.IUsersService;
	import org.osflash.signals.ISignal;
	
	import robotlegs.bender.bundles.mvcs.Mediator;
	
	import spark.events.IndexChangeEvent;
	
	public class ParticipantsViewMediator extends Mediator {
		
		[Inject]
		public var view:IParticipantsView;
		
		[Inject]
		public var userSession:IUserSession
		
		[Inject]
		public var userUISession:IUserUISession
		
		[Inject]
		public var usersService:IUsersService;
		
		protected var dataProvider:ArrayCollection;
		
		protected var dataProviderGuests:ArrayCollection;
		
		protected var dicUserIdtoUser:Dictionary;
		
		protected var dicUserIdtoGuest:Dictionary
		
		protected var usersSignal:ISignal;
		
		private var _userMe:User;
		
		override public function initialize():void {
			dataProvider = new ArrayCollection();
			view.list.dataProvider = dataProvider;
			view.list.addEventListener(IndexChangeEvent.CHANGE, onSelectParticipant);
			dicUserIdtoUser = new Dictionary();
			var users:ArrayCollection = userSession.userList.users;
			for each (var user:User in users) {
				addUser(user);
				if (user.me) {
					_userMe = user;
				}
			}
			userSession.userList.userChangeSignal.add(userChanged);
			userSession.userList.userAddedSignal.add(addUser);
			userSession.userList.userRemovedSignal.add(userRemoved);
			setPageTitle();
			FlexGlobals.topLevelApplication.profileBtn.visible = true;
			FlexGlobals.topLevelApplication.backBtn.visible = false;
			dataProviderGuests = new ArrayCollection();
			view.guestsList.dataProvider = dataProviderGuests;
			view.guestsList.addEventListener(GuestResponseEvent.GUEST_RESPONSE, onSelectGuest);
			FlexGlobals.topLevelApplication.stage.addEventListener(ResizeEvent.RESIZE, stageOrientationChangingHandler);
			view.allowAllButton.addEventListener(MouseEvent.CLICK, allowAllGuests);
			view.denyAllButton.addEventListener(MouseEvent.CLICK, denyAllGuests);
			dicUserIdtoGuest = new Dictionary();
			var guests:ArrayCollection = userSession.guestList.users;
			for each (var guest:User in guests) {
				addGuest(guest);
			}
			userSession.guestList.userAddedSignal.add(addGuest);
			userSession.guestList.userRemovedSignal.add(guestRemoved);
			if (_userMe.role == User.MODERATOR && dataProviderGuests.length > 0) {
				view.guestsList.visible = true;
				view.guestsList.includeInLayout = true;
				view.allGuests.visible = true;
				view.allGuests.includeInLayout = true;
			}
			if (FlexGlobals.topLevelApplication.isTabletLandscape()) {
				if (userUISession.currentPageDetails is User) {
					view.list.setSelectedIndex(dataProvider.getItemIndex(userUISession.currentPageDetails), true);
				} else {
					view.list.setSelectedIndex(0, true);
				}
			}
			var tabletLandscape:Boolean = FlexGlobals.topLevelApplication.isTabletLandscape();
			if (tabletLandscape) {
				userUISession.pushPage(PagesENUM.SPLITPARTICIPANTS);
			} else {
				userUISession.pushPage(PagesENUM.PARTICIPANTS);
			}
		}
		
		private function stageOrientationChangingHandler(e:Event):void {
			var tabletLandscape:Boolean = FlexGlobals.topLevelApplication.isTabletLandscape();
			if (tabletLandscape) {
				userUISession.pushPage(PagesENUM.SPLITPARTICIPANTS);
			}
		}
		
		private function addUser(user:User):void {
			dataProvider.addItem(user);
			dataProvider.refresh();
			dicUserIdtoUser[user.userID] = user;
			setPageTitle();
		}
		
		private function addGuest(guest:Object):void {
			dataProviderGuests.addItem(guest);
			dataProviderGuests.refresh();
			dicUserIdtoGuest[guest.userID] = guest;
			if (_userMe.role == User.MODERATOR && dataProviderGuests.length > 0) {
				view.guestsList.visible = true;
				view.guestsList.includeInLayout = true;
				view.allGuests.visible = true;
				view.allGuests.includeInLayout = true;
			}
		}
		
		private function userRemoved(userID:String):void {
			var user:User = dicUserIdtoUser[userID] as User;
			var index:uint = dataProvider.getItemIndex(user);
			dataProvider.removeItemAt(index);
			dicUserIdtoUser[user.userID] = null;
			setPageTitle();
			if (FlexGlobals.topLevelApplication.isTabletLandscape() && userUISession.currentPageDetails == user) {
				view.list.setSelectedIndex(0, true);
			}
		}
		
		private function guestRemoved(userID:String):void {
			var guest:User = dicUserIdtoGuest[userID] as User;
			if (guest) {
				var index:uint = dataProviderGuests.getItemIndex(guest);
				dataProviderGuests.removeItemAt(index);
				dicUserIdtoGuest[guest.userID] = null;
				if (_userMe.role == User.MODERATOR && dataProviderGuests.length == 0 && view && view.guestsList != null) {
					view.guestsList.includeInLayout = false;
					view.guestsList.visible = false;
					view.allGuests.includeInLayout = false;
					view.allGuests.visible = false;
				}
			}
		}
		
		private function userChanged(user:User, property:String = null):void {
			dataProvider.refresh();
			if (_userMe.role == User.MODERATOR && dataProviderGuests.length > 0) {
				view.guestsList.visible = true;
				view.guestsList.includeInLayout = true;
				view.allGuests.visible = true;
				view.allGuests.includeInLayout = true;
			} else {
				view.guestsList.visible = false;
				view.guestsList.includeInLayout = false;
				view.allGuests.visible = false;
				view.allGuests.includeInLayout = false;
			}
		}
		
		protected function onSelectParticipant(event:IndexChangeEvent):void {
			if (event.newIndex >= 0) {
				var user:User = dataProvider.getItemAt(event.newIndex) as User;
				if (FlexGlobals.topLevelApplication.isTabletLandscape()) {
					eventDispatcher.dispatchEvent(new SplitViewEvent(SplitViewEvent.CHANGE_VIEW, PagesENUM.getClassfromName(PagesENUM.USER_DETAILS), user, true))
				} else {
					userUISession.pushPage(PagesENUM.USER_DETAILS, user, TransitionAnimationENUM.SLIDE_LEFT);
				}
			}
		}
		
		protected function onSelectGuest(event:GuestResponseEvent):void {
			usersService.responseToGuest(event.guestID, event.allow);
		}
		
		protected function allowAllGuests(event:MouseEvent):void {
			usersService.responseToAllGuests(true);
		}
		
		protected function denyAllGuests(event:MouseEvent):void {
			usersService.responseToAllGuests(false);
		}
		
		/**
		 * Count participants and set page title accordingly
		 **/
		private function setPageTitle():void {
			if (dataProvider != null) {
				FlexGlobals.topLevelApplication.pageName.text = ResourceManager.getInstance().getString('resources', 'participants.title') + " (" + dataProvider.length + ")";
			}
		}
		
		override public function destroy():void {
			super.destroy();
			view.dispose();
			view = null;
			FlexGlobals.topLevelApplication.stage.removeEventListener(ResizeEvent.RESIZE, stageOrientationChangingHandler);
			userSession.userList.userChangeSignal.remove(userChanged);
			userSession.userList.userAddedSignal.remove(addUser);
			userSession.userList.userRemovedSignal.remove(userRemoved);
			userSession.guestList.userAddedSignal.remove(addGuest);
		}
	}
}
