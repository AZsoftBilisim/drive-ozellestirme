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
	
	// Values of form details
	CompositionOfSetOfConstantsOfForm    = TMCommonUse.GetStructureOfSetOfConstants(ConstantsSet);
	ExternalParentConstants = SystemSettingsCached.GetStructureOfParentConstants(CompositionOfSetOfConstantsOfForm);
	
	WorkMode = New Structure;
	WorkMode.Insert("CompositionOfSetOfConstantsOfForm",    New FixedStructure(CompositionOfSetOfConstantsOfForm));
	WorkMode.Insert("ExternalParentConstants", New FixedStructure(ExternalParentConstants));
	
	WorkMode = New FixedStructure(WorkMode);
	
	Items.LocalizationGroupNonCurrentAssets22.Visible = False;
	Items.OpenTheTransitionAssistant.Visible = False;
	
	DetermineWhetherAccountingIsAvailable();
	FixedAndIntangibleAssetsAccounting = ValueOfChoiceAccountingForNonCurrentAssets(ConstantsSet);
	
	SystemSettingsLocalization.WhenCreatedOnServer_NonCurrentAssets(ThisForm);
	
	SetFormItemsVisibility();
	SetAvailability();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ConstantsSet" Then
	
		// If it is a changed constant located in a different form and affecting the values of the constants of this form,
		// then we will read the values of the constants and update the elements of this form.
		If WorkMode.ExternalParentConstants.Property(Source)
		 Or (TypeOf(Parameter) = Type("Structure")
		 		And TMCommonUseClientServer.GetSharedKeysOfStructures(
		 			Parameter, WorkMode.ExternalParentConstants).Count() > 0)
		 Or Source = "UseNonCurrentAssets2_4"
		 Or Source = "UseInventoryConsumption" Then
			
			ThisForm.Read();
			FixedAndIntangibleAssetsAccounting = ValueOfChoiceAccountingForNonCurrentAssets(ConstantsSet);
			SetAvailability();
			
		EndIf;
		
	ElsIf EventName = "Write_Companies" Then
		SetAvailability();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OnChangeAttribute(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure WhenYouChangePropsTheBeginningOfTheSelection(Item, ChoiceData, StandardProcessing)
	
	SystemSettingsClientLocalization.WhenChangingDetailsBeginningOfSelection_NonCurrentAssets(
		ThisForm,
		Item,
		ChoiceData,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure FixedAndIntangibleAssetsAccountingOnChange(Item)
	
	DetermineWhetherAccountingIsAvailable();
	
	Cancel = False;
	
	If FixedAndIntangibleAssetsAccounting = "2_4" And Not AccountingAvailability24.AccountingIsAvailable Then
		
		ShowMessageBox(, AccountingAvailability24.Comment2_4); 
		
		Cancel = True;
	
	Else
		
		SystemSettingsClientLocalization.FixedAndIntangibleAssetsAccountingOnChange(ThisForm, Cancel);
		
	EndIf;
	
	If Cancel Then
		FixedAndIntangibleAssetsAccounting = ValueOfChoiceAccountingForNonCurrentAssets(ConstantsSet);
		Return;
	EndIf;
	
	// When downgrading the version, you need to warn the user
	QueryText = "";
	If FixedAndIntangibleAssetsAccounting = ""
		And ConstantsSet.UseNonCurrentAssets2_4 Then
			
		If Not AccountingPresence.YouCanDisableAccounting Then
			QueryText = NStr("vi = 'Không nên tắt tính năng kế toán tài sản dài hạn sau khi bắt đầu làm việc với hệ thống.
		                            |Tiếp tục điều chỉnh?';
		                            |ru = 'Отключать учет внеоборотных активов после начала работы с системой не рекомендуется.
		                            |Продолжить редактирование?';
		                            |en = 'It is not recommended that you disable fixed and intangible assets accounting after you start working with the application.
		                            |Continue editing?'; fa = 'It is not recommended that you disable fixed and intangible assets accounting after you start working with the application.
		                            |Continue editing?';
		                            |it = 'Non è consigliabile disabilitare la contabilità di attivi non circolanti dopo che il lavoro con il sistema è stato iniziato.
		                            |Continuare le modifiche?';
		                            |pl = 'Wyłączenie ewidencji trwałych aktywów po rozpoczęciu pracy z systemem nie jest zalecane.
		                            |Kontynuować edycję?';
		                            |tr = 'Sistemle çalışmaya başladıktan sonra duran varlıkların muhasebesini devre dışı bırakılması önerilmiyor.
		                            |Düzenlemeye devam et?'");
		EndIf;
		
	Else
		
		SystemSettingsClientLocalization.WhenLoweringVersionOfAccountingForNonCurrentAssets(ThisForm, QueryText);
		
	EndIf;
	
	If QueryText <> "" Then
		CallbackDescription = New CallbackDescription("FixedAndIntangibleAssetsAccountingOnChangeCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		Attachable_OnChangeAttribute(Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure SeparationOptionCleaningUp(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region Private

#Region Client

// Parameters:
// 	TagName - String -
// 	AdditionalParameters - Structure:
//		* ProcessingParameters - Structure:
//			** Item - FormField
//			** ShouldRefreshInterface - Boolean
&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, AdditionalParameters) Export
	Attachable_OnChangeAttribute(
		AdditionalParameters.ProcessingParameters.Item, 
		AdditionalParameters.ProcessingParameters.ShouldRefreshInterface);
EndProcedure

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
Procedure Attachable_Click(Item)
	
	SystemSettingsClientLocalization.PushEventHandling_NonCurrentAssets(Item, ThisForm);
		
EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtClient
Procedure FixedAndIntangibleAssetsAccountingOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		Attachable_OnChangeAttribute(Items.FixedAndIntangibleAssetsAccounting);
	Else
		FixedAndIntangibleAssetsAccounting = ValueOfChoiceAccountingForNonCurrentAssets(ConstantsSet);
	EndIf;
	
EndProcedure

#EndRegion

#Region ServerCall

&AtServer
Function OnChangeAttributeServer(TagName)
	
	DataPathAttribute = Items[TagName].DataPath;
	
	ConstantName = SaveAttributeValue(DataPathAttribute, New Structure);
	
	SetAvailability(DataPathAttribute);
	
	RefreshReusableValues();
	
	Return ConstantName;
	
EndFunction

#EndRegion

#Region Server

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
			ThisForm.Read();
		EndIf;
		
	EndIf;
	
	If DataPathAttribute = "FixedAndIntangibleAssetsAccounting" Then
		
		If FixedAndIntangibleAssetsAccounting = "2_4" Then
			ConstantName = "UseNonCurrentAssets2_4";
			ConstantsSet.UseNonCurrentAssets2_4 = True;
		ElsIf FixedAndIntangibleAssetsAccounting = "" Then
			ConstantName = "UseNonCurrentAssets2_4";
			ConstantsSet.UseNonCurrentAssets2_4 = False;
		EndIf;
		
		If Constants.UseNonCurrentAssets2_4.Get() <> ConstantsSet.UseNonCurrentAssets2_4 Then
			
			Constants.UseNonCurrentAssets2_4.Set(ConstantsSet.UseNonCurrentAssets2_4);
			
			If SystemSettingsCached.ThereAreSubordinateConstants("UseNonCurrentAssets2_4", ConstantsSet.UseNonCurrentAssets2_4) Then
				ThisForm.Read();
			EndIf;
			
		EndIf; 
		
	EndIf;
	
	NonCurrentAssetsLocalization.SavePropsValue_KaAdministrationPanel(
		ThisForm, DataPathAttribute, ConstantName);
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure SetFormItemsVisibility()
	
	EnterpriseManagement = GetFunctionalOption("EnterpriseManagement");
	
	Items.GroupSettingsRepairs.Visible = EnterpriseManagement;
	Items.GroupAccountingForNonCurrentAssets.ShowTitle = EnterpriseManagement;
	
EndProcedure

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	DetermineAvailabilityOfAccounting2_4();
	
	If DataPathAttribute = "ConstantsSet.UseNonCurrentAssets2_4" 
		Or DataPathAttribute = "FixedAndIntangibleAssetsAccounting" 
		Or DataPathAttribute = "" Then
		
		Items.UseConstructionObjects.Visible = ConstantsSet.UseNonCurrentAssets2_4;
		Items.GroupToUseImpairmentIn.Visible = ConstantsSet.UseNonCurrentAssets2_4;
		Items.GroupUsedTransferForLease.Visible = ConstantsSet.UseNonCurrentAssets2_4;
	
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseConstructionObjects" 
		Or DataPathAttribute = "FixedAndIntangibleAssetsAccounting"
		Or DataPathAttribute = "" Then
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseConstructionObjects, 
			ConstantsSet.UseConstructionObjects And AccountingPresence.ThereIsAccounting2_4);
	EndIf;
		
	If DataPathAttribute = "ConstantsSet.UseFixedAssetImpairment" 
		Or DataPathAttribute = "FixedAndIntangibleAssetsAccounting"
		Or DataPathAttribute = "" Then
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseFixedAssetImpairment, 
			ConstantsSet.UseFixedAssetImpairment And AccountingPresence.ThereIsAccounting2_4);
	EndIf;
		
	If DataPathAttribute = "ConstantsSet.TransferToRentalSubleaseBasedOnRussianGAAPFSBU25" 
		Or DataPathAttribute = "FixedAndIntangibleAssetsAccounting"
		Or DataPathAttribute = "" Then
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.TransferToRentalSubleaseBasedOnRussianGAAPFSBU25, 
			ConstantsSet.TransferToRentalSubleaseBasedOnRussianGAAPFSBU25 And AccountingPresence.ThereIsAccounting2_4);
	EndIf;
		
	If DataPathAttribute = "ConstantsSet.UseSubAssets" 
		Or DataPathAttribute = "" Then
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseSubAssets,
			ConstantsSet.UseSubAssets);
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseRMManagement" 
		Or DataPathAttribute = "" Then
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseRMManagement,
			ConstantsSet.UseRMManagement);
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseRMManagement" Or DataPathAttribute = "" Then
		Items.UseSubAssets.Enabled = ConstantsSet.UseRMManagement;
		Items.OptionOfMaterialAssignmentInRM.Enabled = ConstantsSet.UseRMManagement
			And Constants.GenerateFinancialResult.Get();
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseInventoryConsumption"
		Or DataPathAttribute = "" Then
		
		ConstantValue = ConstantsSet.UseInventoryConsumption;
		
		Items.UseInventoryConsumptionStatuses.Enabled = ConstantValue;
		Items.CommentGroupUsesInternalConsumptionStatuses.Visible = Not ConstantValue;
		
	EndIf;
	
	If DataPathAttribute = "ConstantsSet.UseInventoryConsumptionStatuses"
		Or DataPathAttribute = "" Then
		
		ConstantValue = ConstantsSet.UseInventoryConsumptionStatuses;
		
		TMCommonUseClientServer.WarningOnEditRepresentation(
			Items.UseInventoryConsumptionStatuses, ConstantValue);
			
	EndIf;
	
	UseOrderSupplyWithAssignment = Constants.UseOrderSupplyWithAssignment.Get();
	Items.GroupOptionForSeparatingMaterialsInRepairs.Visible = UseOrderSupplyWithAssignment;
	SystemSettingsLocalization.EstablishAvailability_NonCurrentAssets(ThisForm, DataPathAttribute);
	
EndProcedure

&AtServer
Procedure DetermineAvailabilityOfAccounting2_4()
	
	AccountingAvailability24 = New FixedStructure(NonCurrentAssets.ConditionsForSwitchingToAccounting2_4());
	
EndProcedure

&AtClientAtServerNoContext
Function ValueOfChoiceAccountingForNonCurrentAssets(ConstantsSet)

	If ConstantsSet.UseNonCurrentAssets2_4 Then
		Return "2_4";
	ElsIf ConstantsSet.UseNonCurrentAssets2_2 Then
		Return "2_2";
	Else
		Return "";
	EndIf; 

EndFunction

&AtServer
Procedure DetermineWhetherAccountingIsAvailable()

	AvailabilityOfAccountingInProgram = New Structure;
	AvailabilityOfAccountingInProgram.Insert("ThereIsAccounting", NonCurrentAssetsInternal.ThereIsAccountingOfNonCurrentAssets());
	AvailabilityOfAccountingInProgram.Insert("ThereIsAccounting2_4", NonCurrentAssetsInternal.ThereIsAccountingOfNonCurrentAssets2_4());
	AvailabilityOfAccountingInProgram.Insert("YouCanDisableAccounting", Not AvailabilityOfAccountingInProgram.ThereIsAccounting And Not AvailabilityOfAccountingInProgram.ThereIsAccounting2_4);
			
	NonCurrentAssetsLocalization.AddAccountingInformation(AvailabilityOfAccountingInProgram);
	
	AccountingPresence = New FixedStructure(AvailabilityOfAccountingInProgram);
	
EndProcedure

#EndRegion

#EndRegion