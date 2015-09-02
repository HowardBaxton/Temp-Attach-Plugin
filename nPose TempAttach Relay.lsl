/*
This nPose plugin only need be used if you wish to offer a temp attach item to another seated AV.  This script keeps track of seated AV uuid's and their seat number on the build.
This script also has the ability to add a layered animation at the same time temp attach is offered.  An example might be to bend the elbow and position the AV's arm to hold a glass which you intend for temp attach.  Add the following lines to a BTN notecard.

PROP|Glass Of Orange Juice for nPose|<0,0,0.5>|<0,0,0>
LINKMSG|-6001|1/attach/6/start/sip rest loop

Use the PROP line to rez the glass, then use the LINKMSG to send a message to this plugin.  The LINKMSG above will offer the temp attach to the sitter in seat 1 at attach point 6.  It will also send the "start" command for animation "sip rest loop".

NOTE:
-----------
Be aware that layered animations must be managed by you (the builder).  Layered animations do not stop on their own, you must tell them to stop.
-----------

This plugin can also be used to get the attach item and layered animations for menu toucher.  Simply replace the seat number with %AVKEY% as follows:

PROP|Glass Of Orange Juice for nPose|<0,0,0.5>|<0,0,0>
LINKMSG|-6001|%AVKEY%/attach/6/start/sip rest loop

This relay also supports detach.  Be aware that all temp attached items will be detached.  If a single temp attached item need be removed, it is recommended to talk directly to the "nPose TempAttach object" script via -6002.  See the notes inside plugin "nPose TempAttach object" script.
*/

integer chatchannel;
integer seatupdate = 35353;
list avList=[];


default{
    state_entry() {
        llMessageLinked(LINK_SET, 999999, "", NULL_KEY);
    }
    
    link_message(integer sender, integer num, string str, key id) {
        if(num == -6001) {
            list tempList = llParseStringKeepNulls(str, ["/"],[]);
            string seat = llList2String(tempList, 0);
            integer index;
            //support method of %AVKEY% instead of seat number
            if((key)seat) {
                seat = llList2String(avList, llListFindList(avList, [(key)seat]) + 2);
            }
            
            string attachCommand = llList2String(tempList, 1);
            string attachPoint = llList2String(tempList, 2);
            string animCommand = llList2String(tempList, 3);
            string animName = llList2String(tempList, 4);
            index = llListFindList(avList, [(integer)seat]);
            if((index != -1) && (llList2String(avList, index-2) != "") && (attachCommand != "")) {
                string sendStr = "LINKMSG|-6003|" + attachCommand+"/"+attachPoint+"/"+ llList2String(avList, index-2);
                llRegionSay(chatchannel,sendStr);
            }
            if((animCommand != "") && (animName != "") && (index != -1)) {
                string sendStr = llList2String(avList, index-2)+"/"+animCommand+","+animName;
                llMessageLinked(LINK_SET, -218, sendStr, NULL_KEY);
            }
        }
        else if(num == seatupdate) {
            avList = [];
            list tempList = llParseStringKeepNulls(str, ["^"], []);
            integer stop = llGetListLength(tempList)/8;
            integer n;
            for(n=0; n<stop; ++n) {
                string AV = llList2String(tempList, (n*8)+4);
                string seatStr = llList2String(tempList, n*8+7);
                integer index = llSubStringIndex(seatStr, "seat");
                integer seatNum = (integer)llGetSubString(seatStr, index + 4,-1);
                if(AV!="") {
                    avList += [(key)AV, llGetSubString(llKey2Name((key)AV),0,20), seatNum];
                }
            }
        }
        else if(num == 1) {  //got chatchannel from the core.
            chatchannel = (integer)str;
        }
        else if(num == 34334) {
            llSay(0,"Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit()
                 + ",Leaving " + (string)llGetFreeMemory() + " memory free.");
        }
    }
}
