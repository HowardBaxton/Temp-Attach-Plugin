key userKey;
integer attachPoint;
integer listenChannel;

default
{

    touch_start(integer total_number)
    {
        userKey = llDetectedKey(0);
        attachPoint = (integer)llGetObjectDesc();
        llRequestPermissions(userKey, PERMISSION_ATTACH);
    }
 
    run_time_permissions(integer vBitPermissions){
        if ((vBitPermissions & PERMISSION_ATTACH) && llGetPermissionsKey() == userKey){
            if (!llGetAttached() && attachPoint > 0){
                llAttachToAvatarTemp(attachPoint);
                userKey = "";
            }
        }else{
            llRegionSayTo(userKey, 0, "Permission was not granted.");
        }
    }
    
     listen( integer channel, string name, key id, string message) {
         if (channel == listenChannel){
            list tempList1 = llParseString2List(message, ["|"], []);
            if (llList2String(tempList1, 0) == "pong"){
                //someone has sent out a ping (request for parentID. Only the nPose core sends "Pong", grab the parentID.
//                parentID = id;
                return;
            }
            list tempList = llParseString2List(llList2String(tempList1, 2), ["/"], []);
            string varItem = llList2String(llParseString2List(llList2String(tempList, 0), ["="], []), 0);
            string varCmd = llList2String(llParseString2List(llList2String(tempList, 0), ["="], []), 1);
            attachPoint = (integer)llList2String(tempList, 1);
            userKey = (key)llList2String(tempList1, 3);
            if ((llList2String(tempList1, 1) == "-6002")
             && ((llGetAttached()) && (varCmd == "detach") && (llGetObjectName() == varItem) && (llGetPermissionsKey() == userKey))){
                llDetachFromAvatar();
            }
        }
    }

    on_rez(integer rez){
        listenChannel = (integer)((0x00FFFFFF & (rez >> 8)) + 0x7F000000);
        integer listen_handle = llListen(listenChannel, "","", "");
    }
    
    changed(integer change){
        if (change & CHANGED_OWNER){
            if (llGetAttached()){
                llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
            }
        }
    }
}
