#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CompositionOfSetOfConstantsOfForm = TMCommonUse.GetStructureOfSetOfConstants(ConstantsSet);
	ExternalParentConstants = SystemSettingsCached.GetStructureOfParentConstants(CompositionOfSetOfConstantsOfForm);
	WorkMode = New Structure;
	
	WorkMode.Insert("CompositionOfSetOfConstantsOfForm",    New FixedStructure(CompositionOfSetOfConstantsOfForm));
	WorkMode.Insert("ExternalParentConstants", New FixedStructure(ExternalParentConstants));
	
	WorkMode = New FixedStructure(WorkMode);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName <> "Write_ConstantsSet" Then
		Return; // such events are not processed
	EndIf;
	
	If Source = ThisObject Then
		If Parameter.Property("Item") Then
			Attachable_OnChangeAttribute(Parameter.Item, True, True);
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ConstantsSetUseDemoScenariosOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

#EndRegion

#Region FormCommands

&AtClient
Procedure GeneratingInformationAboutSupport(Command)
	
	OpenForm("DataProcessor.ProcessDetailsExport.Form.SupportSetting",,,
	            ,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

 #EndRegion

#Region Private

&AtClient
Procedure Attachable_OnChangeAttribute(Item, ShouldRefreshInterface = True, ExternalUpdate = False)
	
	If Not ExternalUpdate Then
		SystemSettingsClientLocalization.WhenChangingBankingDetails_Sales(
			Item,
			ThisObject);
	EndIf;
	
	ConstantName = OnChangeAttributeServer(Item.Name);
	
	If ShouldRefreshInterface Then
		RefreshInterface = True;
		AttachIdleHandler("RefreshApplicationInterface", 2, True);
	EndIf;
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtServer
Function OnChangeAttributeServer(TagName)
	
	DataPathAttribute = Items[TagName].DataPath;
	
	ConstantName = SaveAttributeValue(DataPathAttribute,  New Structure);
	
	RefreshReusableValues();
	
	Return ConstantName;
	
EndFunction 

&AtServer
Function SaveAttributeValue(DataPathAttribute, Result)
	
	// Storing the values of the details that are not directly related to the constants (in a one-to-one relationship).
	If DataPathAttribute = "" Then
		Return "";
	EndIf;
	
	// Definition of the constant name.
	ConstantName = "";
	If StrStartsWith(Lower(DataPathAttribute), Lower("ConstantsSet.")) Then
		// If the path to the data of the props is specified through the "Setconstant".
		NameParts = StrSplit(DataPathAttribute, ".");
		ConstantName = NameParts[1];
	EndIf;
	
	If IsBlankString(ConstantName) Then 
		Return "";
	EndIf;
	
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	
	If ConstantManager.Get() <> ConstantValue Then
		ConstantManager.Set(ConstantValue);
	EndIf;
	
	If SystemSettingsCached.ThereAreSubordinateConstants(ConstantName, ConstantValue) Then
		Read();
	EndIf;
	
	Return ConstantName;
	
EndFunction

#EndRegion
