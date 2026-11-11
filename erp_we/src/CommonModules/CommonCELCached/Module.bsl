
#Region Internal

// Returns a match between the names of "functional" subsystems and the value True.
// The" functional "subsystem has the" Include in command interface " checkbox unchecked.
// 
// Returns:
//   Map of KeyAndValue
//
Function SubsystemsNames() Export
	
	Names = New Map;
	InsertSubordinateSubsystemNames(Names, Metadata);
	
	Return New FixedMap(Names);
	
EndFunction

Function SubstitutionModeIsAvailable() Export
	
	SystemInfo = New SystemInfo();
	Version = SystemInfo.AppVersion;
	
	If CommonCELClientServer.CompareVersions(Version, "8.3.25.1336") < 0 Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function ReplacementModeDeletion() Export
	
#If Not MobileAppServer Then
	SetSafeMode(True);
#EndIf
	Return Eval("ReplacementMode.Delete");
	
EndFunction

Function ClientNotificationsAreAvailable() Export

	SystemInfo = New SystemInfo();
	Version = SystemInfo.AppVersion;
	
	If CommonCELClientServer.CompareVersions(Version, "8.3.27.1508") < 0 Then
		Return False;
	EndIf;
	
	Return True;

EndFunction

Function ClientNotifications() Export
	
#If Not MobileAppServer Then
	SetSafeMode(True);
#EndIf
	Return Eval("ClientNotifications");
	
EndFunction



#EndRegion


#Region Private

Procedure InsertSubordinateSubsystemNames(Names, ParentSubsystem, ParentSubsystemName = "")
	
	For Each CurrentSubsystem In ParentSubsystem.Subsystems Do
		
		If CurrentSubsystem.IncludeInCommandInterface Then
			Continue;
		EndIf;
		
		CurrentSubsystemName = ParentSubsystemName + CurrentSubsystem.Name;
		Names.Insert(CurrentSubsystemName, True);
		
		If CurrentSubsystem.Subsystems.Count() = 0 Then
			Continue;
		EndIf;
		
		InsertSubordinateSubsystemNames(Names, CurrentSubsystem, CurrentSubsystemName + ".");
	EndDo;
	
EndProcedure

#EndRegion
