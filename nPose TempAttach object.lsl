/*
IMPORTANT NOTES:
-----------------
TEMP ATTACH ITEMS WILL BE DELETED ONCE REZZED INWORLD.  PLEASE TAKE CARE TO USE ONLY ITEMS WITH COPY PERMISSIONS.
Any items intended to be temp attached to anyone other than the build owner must have transfer permissions.
If you (as menu user) wish to offer a temp attach item to any other sitter besides you, using the "nPose TempAttach Relay" plugin in conjunction with this one will be needed.
-----------------


Use this plugin in all temp attach items.  nPose will talk to this script on the nPose build's chat channel, even after attached to another AV besides the nPose build owner.

Make a BTN notecard with the following contents to rez and temp attach "Male Create Glasses":
PROP|Male Create Glasses|<-1.0,0,1.5>|<0,0,0>
LINKMSG|-6002|Male Create Glasses=attach/17|%AVKEY%

Make another BTN notecard with the folloing contents to detach "Male Create Glasses":
LINKMSG|-6002|Male Create Glasses=detach/17|%AVKEY%


*/

string varCmd;
string varItem;
key userKey;
list avList;
integer listen_handle;
integer listenChannel;
integer attachPoint;
float timerInc = 60.0;
key parentID = NULL_KEY;
key agentWhoGavePermission;


default {
    state_entry() {
        llSetTimerEvent(timerInc);
        listen_handle = llListen(listenChannel, "","", "");
    }
 
    run_time_permissions(integer vBitPermissions){
        if((vBitPermissions & PERMISSION_ATTACH) && llGetPermissionsKey() == userKey) {
            if((!llGetAttached()) && (varCmd == "attach") && (llGetObjectName() == varItem)) {
                llAttachToAvatarTemp(attachPoint);
                agentWhoGavePermission = userKey;
                userKey = "";
            }
        }
        else {
            llRegionSayTo(userKey, 0, "Permission was not granted.");
            llDie();
        }
    }

     listen( integer channel, string name, key id, string message) {
         if(channel == listenChannel) {
            list tempList1 = llParseString2List(message, ["|"], []);
            if (llList2String(tempList1, 0) == "pong"){
                //someone has sent out a ping (request for parentID. Only the nPose core sends "Pong", grab the parentID.
                parentID = id;
                return;
            }
            list tempList = llParseString2List(llList2String(tempList1, 2), ["/"], []);
            //-6003 indicating the temp attach relay sent this attach message... used to offer attachment to another sitter
            //the temp attach relay has been keeping track of which AV is seated where
            if(llList2String(tempList1, 1) == "-6003") {
                varCmd = llList2String(tempList, 0);
                varItem = llGetObjectName();
                attachPoint = (integer)(llList2String(tempList, 1));
                if (userKey){
                }
                else {
                    userKey = (key)llList2String(tempList, 2);
                }
                if((!llGetAttached()) && (varCmd == "attach") && (llGetObjectName() == varItem) && (llKey2Name(userKey) != "")) {
                    //don't do attach if no one is seated in our seat.
                    string objName = llGetObjectName();
                    llSetObjectName("");
                    llRegionSayTo(userKey, 0, "Please say Yes to the permissions popup.\nnPose would like to temp" + varCmd + " "
                     + objName + " " + llGetObjectName() + " to your Avatar.");
                    llSetObjectName(objName);
                    llRequestPermissions(userKey, PERMISSION_ATTACH);
                }
                else if((llGetAttached()) && (varCmd == "detach") && (llGetObjectName() == varItem)
                 && (agentWhoGavePermission == userKey)) {
                    //only detach if our AV has given permissions to attach
                    llDetachFromAvatar();
                }
            //-6002 indicating this came directly from nPose... we attaching to menu user
            //this item was rezzed by nPose and knows the chatchannel when rezzed so nPose can talk to this item directly
            }
            else if(llList2String(tempList1, 1) == "-6002"
              && llGetObjectName() == llList2String(llParseString2List(llList2String(tempList, 0), ["="], []), 0)) {
                //method 2 
                varItem = llList2String(llParseString2List(llList2String(tempList, 0), ["="], []), 0);
                varCmd = llList2String(llParseString2List(llList2String(tempList, 0), ["="], []), 1);
                attachPoint = (integer)llList2String(tempList, 1);
                userKey = (key)llList2String(tempList1, 3);
                if((!llGetAttached()) && (varCmd == "attach") && (llGetObjectName() == varItem)) {
                    string objName = llGetObjectName();
                    llSetObjectName("");
                    llRegionSayTo(userKey, 0, "Please say Yes to the permissions popup.\nnPose would like to temp" + varCmd + " "
                     + objName + " to your Avatar.");
                    llSetObjectName(objName);
                    llRequestPermissions(userKey, PERMISSION_ATTACH);
                }
                else if((llGetAttached()) && (varCmd == "detach") && (llGetObjectName() == varItem)
                 && (agentWhoGavePermission == userKey)) {
                    llDetachFromAvatar();
                }
            }
            else if((integer)llList2String(tempList1, 1) == 35353) {
                avList = [];
                list tempList2 = llParseStringKeepNulls(llList2String(tempList1, 2), ["^"], []);
                integer stop = llGetListLength(tempList2)/8;
                integer n;
                for(n=0; n<stop; ++n) {
                    string AV = llList2String(tempList2, (n*8)+4);
                    integer seatNum = (integer)llGetSubString(llList2String(tempList2, n*8+7), 4,-1);
                    if(AV!="") {
                        avList += [(key)AV, llGetSubString(llKey2Name((key)AV),0,20), seatNum];
                    }
                }
            }
        }
    }

    timer() {
        if((timerInc == 60.0) && (listenChannel != 0)) {
            if(!llGetAttached()) {
                llDie();
            }
            else {
                llRegionSay(listenChannel, "ping");
                timerInc = 10;
                llSetTimerEvent(timerInc);
            }
        }else if(llKey2Name(parentID) == "") {
            //we have not received a parentID from the nPose core.
            llDie();
        }
    }

    on_rez(integer rez) {
        listenChannel = (integer)((0x00FFFFFF & (rez >> 8)) + 0x7F000000);
        listen_handle = llListen(listenChannel, "","", "");
        llSetTimerEvent(60.0);
    }
    
    changed(integer change) {
        if(change & CHANGED_OWNER) {
            if(llGetAttached()) {
                llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
            }
        }
    }
}
