
#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	CompositionOfSetOfConstantsOfForm    = TMCommonUse.GetStructureOfSetOfConstants(ConstantsSet);
	ExternalParentConstants = SystemSettingsCached.GetStructureOfParentConstants(CompositionOfSetOfConstantsOfForm);
	ExternalParentConstants.Insert(Metadata.Constants.PayrollAndHumanResourcesWE.Name);
	
	WorkMode = New Structure;
	WorkMode.Insert("CompositionOfSetOfConstantsOfForm",    New FixedStructure(CompositionOfSetOfConstantsOfForm));
	WorkMode.Insert("ExternalParentConstants", New FixedStructure(ExternalParentConstants));
	
	WorkMode = New FixedStructure(WorkMode);
	
	ConfigureDependentFormElements();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName <> "Write_ConstantsSet" Then
		Return; // such events are not processed
	EndIf;
	
	// If it is a changed constant located in a different form and affecting the values of the constants of this form,
	// then we will read the values of the constants and update the elements of this form.
	If WorkMode.ExternalParentConstants.Property(Source)
	 Or (TypeOf(Parameter) = Type("Structure")
	 		And TMCommonUseClientServer.GetSharedKeysOfStructures(
	 			Parameter, WorkMode.ExternalParentConstants).Count() > 0) Then
		
		Read();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SetOfConstantsStartDatePayrollAndPersonnelStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	PeriodSelectionFormParameters = New Structure("Value, PeriodSelectionMode", ConstantsSet.StartDatePayrollAndHumanResources, "MONTH");
	CallbackDescription = New CallbackDescription("StartDateOfManagementPayrollAndPersonnelCompletion", ThisObject);
	OpenForm("CommonForm.PeriodSelection",
		PeriodSelectionFormParameters, 
		ThisObject, 
		UUID, 
		, 
		, 
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetOfConstantsToUsePersonnelAccountingAndPayrollCalculationOnChange(Item)

	Attachable_OnChangeAttribute(Item);

EndProcedure

&AtClient
Procedure SetOfConstantsStartDatePayrollAndPersonnelOnChange(Item)

	Attachable_OnChangeAttribute(Item);
	
EndProcedure

#EndRegion

#Region Private

#Region Client

&AtClient
Procedure Attachable_OnChangeAttribute(Item, ShouldRefreshInterface = True)
	
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

 #EndRegion

 #Region ServerCall

&AtServer
Function OnChangeAttributeServer(TagName)
	
	DataPathAttribute = Items[TagName].DataPath;
	
	ConstantName = SaveAttributeValue(DataPathAttribute, New Structure);
	
	ConfigureDependentFormElements();
	
	RefreshReusableValues();

	Return ConstantName;
	
EndFunction

#EndRegion

#Region Server

&AtClient
Procedure StartDateOfManagementPayrollAndPersonnelCompletion(SelectionResult, AddlParameters) Export
	
	If SelectionResult = Undefined Then
		Return;
	EndIf;
	
	ConstantsSet.StartDatePayrollAndHumanResources = SelectionResult;
	Attachable_OnChangeAttribute(Items.SetOfConstantsStartDatePayrollAndPersonnel);
	
EndProcedure

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
	Else
		// Defining the name and recording the value of the props in the corresponding constant from the "Setconstant".
		// It is used for those form details that are directly related to constants (in a one-to-one relationship).
	EndIf;
	
	// Saving the value of a constant.
	If ConstantName <> "" Then
		ConstantManager = Constants[ConstantName];
		ConstantValue = ConstantsSet[ConstantName];
		
		If ConstantManager.Get() <> ConstantValue Then
			ConstantManager.Set(ConstantValue);
		EndIf;
		
		If SystemSettingsCached.ThereAreSubordinateConstants(ConstantName, ConstantValue) Then
			Read();
		EndIf;
		
	EndIf;
	
	If ConstantName = "PayrollAndHumanResourcesWE" Then
		
		If Not ConstantsSet.PayrollAndHumanResourcesWE Then
			Constants.StartDatePayrollAndHumanResources.Set(Date(1,1,1));
			Constants.StartDateOfRecordKeepingOfLaborCostsForEmployees.Set(Date(1,1,1)); 
	 	Else
			Constants.StartDatePayrollAndHumanResources.Set(BegOfMonth(CurrentSessionDate())); 
			Constants.StartDateOfRecordKeepingOfLaborCostsForEmployees.Set(BegOfMonth(CurrentSessionDate()));
		EndIf; 
	ElsIf ConstantName = "StartDatePayrollAndHumanResources" 
				And ConstantsSet.PayrollAndHumanResourcesWE 
				And ConstantsSet.StartDatePayrollAndHumanResources = Date(1,1,1) Then   
			Constants.StartDatePayrollAndHumanResources.Set(BegOfMonth(CurrentSessionDate()));
			Constants.StartDateOfRecordKeepingOfLaborCostsForEmployees.Set(BegOfMonth(CurrentSessionDate()));
	ElsIf ConstantName = "StartDatePayrollAndHumanResources"
				And Not ConstantsSet.StartDatePayrollAndHumanResources = ConstantsSet.StartDateOfRecordKeepingOfLaborCostsForEmployees Then
			Constants.StartDateOfRecordKeepingOfLaborCostsForEmployees.Set(ConstantsSet.StartDatePayrollAndHumanResources);
			ConstantsSet.StartDateOfRecordKeepingOfLaborCostsForEmployees = ConstantsSet.StartDatePayrollAndHumanResources; 
	EndIf;	
	
	Return ConstantName
	
EndFunction

&AtServer
Procedure ConfigureDependentFormElements()
	
	Items.SetOfConstantsStartDatePayrollAndPersonnel.ReadOnly = 
											Not ConstantsSet.PayrollAndHumanResourcesWE;  
	
EndProcedure

#EndRegion

	
#EndRegion
	