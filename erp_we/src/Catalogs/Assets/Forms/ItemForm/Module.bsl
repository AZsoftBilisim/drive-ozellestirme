
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", False);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	If Parameters.Property("ReportAboutErrors") And Parameters.ReportAboutErrors Then
		
		PerformFillCheckOnServer();
		
	EndIf;
	#Region UniversalMechanisms
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	ObjectAttributesLock.LockAttributes(ThisObject);
	#EndRegion
	
	SetVisibilityOfInputCommandsBasedOn_();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	If UseRMManagement Then
		
		If CheckCorrectnessWhenSaving Then
			
			PerformFillCheckOnServer(Cancel);
			
		EndIf
		
	EndIf;
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	CurrentObject.HouseholdObject = Boolean(ClassificationDM4);
	
	CurrentObject.RunningTimeRecordingParameters.Load(
		RunningTimeRecordingParameters.Unload(, "RunningTimeValue, AssignedResource, SourceOfParameter"));
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	CheckCorrectnessWhenSaving = False;
	ErrorsInSubnodes = False;
	
	FillInDisplayParameters(CurrentObject);
	FillInParametersForAccountingForDevelopments(CurrentObject.RunningTimeRecordingParameters, CurrentObject.Class);
	ConfigureDependentFormElements(ThisObject, "Ref");
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	RefreshFormTitle();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UnlockingObjectOfOperation" Then
		If Parameter.Asset = Object.Ref Then
			IsBeingEdited = True;
			AttachIdleHandler("Attachable_UpdateForm", 1);
		EndIf;
	ElsIf EventName = "Write_MaintenanceSchemes" Then
		AttachIdleHandler("Attachable_UpdateForm", 1);
	ElsIf EventName = "Write_FixedAssetsInitialRecognition"
		Or EventName = "Write_AdoptionOfAccountingFAInternationalAccounting"
		Or EventName = "Write_DisposeFixedAssets"
		Or EventName = "Write_FAWriteOffInternationalAccounting"
		Or EventName = "Write_FixedAssetsInitialRecognition2_4" 
		Or EventName = "Write_FATransfer2_4" 
		Or EventName = "Write_ReceiveLeasedAssets"
		Or EventName = "Write_ChangeFixedAssetFinancialDetails2_4"
		Or EventName = "Write_DisposeFixedAssets2_4" Then
		WhenChangingFADocuments();
	EndIf;
	
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	AssetsClientLocalization.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Assets.Form.AttributeUnlocking") Then
		ObjectAttributesLockClient.SetFormItemEnabled(ThisObject, ValueSelected);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	Notify("Write_Assets", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ErrorsInSubnodesClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	If ValueIsFilled(NodeWithErrors) Then
		
		OpenForm(
			"Catalog.SubAssets.ObjectForm",
			New Structure(
				"Key, ReportAboutErrors",
				NodeWithErrors, True));
		
	Else
		
		OpenForm(
			"Report.ControlOfAccuracyOfAssetPopulation.Form",
			New Structure(
				"Asset",
				Object.Ref));
		
	EndIf;
EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	
	Items.DescriptionFull.ChoiceList.Clear();
	Items.DescriptionFull.ChoiceList.Add(Object.Description);
	
	If Not ValueIsFilled(Object.DescriptionFull) Then
		Object.DescriptionFull = Object.Description;
	EndIf;
	
EndProcedure

&AtClient
Procedure ClassOnChange(Item)
	
	ClassWhenModifiedOnServer();
	ClearMessages();
	
EndProcedure

&AtClient
Procedure OSTypeOnChange(Item)
	
	ChangedBankingDetails = Item.Name;
	
	If Not ValueIsFilled(Object.Status) 
		And UseRMManagement
		And (Object.OSType = PredefinedValue("Enum.FATypes.Asset")
			Or Object.OSType = PredefinedValue("Enum.FATypes.Node")) Then
				
		Object.Status = PredefinedValue("Enum.AssetStatuses.IsBeingEdited");
		ChangedBankingDetails = ChangedBankingDetails + "," + "Status";
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure InformationAcceptedForAccountingNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If StrFind(FormattedStringURL, "#Create") <> 0 Then
		StandardProcessing = False;
		FormParameters = New Structure("Basis", Object.Ref);
		OpenForm("Document.FixedAssetsInitialRecognition2_4.ObjectForm", FormParameters);
	EndIf; 
	
EndProcedure

&AtClient
Procedure InformationLocationAddressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	ContactsManagerClient.ShowAddressOnMap(FormattedStringURL, "Yandex.Maps");
	
EndProcedure

#Region Localization

&AtClient
Procedure Attachable_OnChangeAttribute(Item)

	AssetsClientLocalization.OnChangeAttribute(Item.Name, ThisForm);

EndProcedure

&AtClient
Procedure Attachable_StartSelectingProps(Item, ChoiceData, StandardProcessing)
	
	AssetsClientLocalization.StartSelectingProps(ThisForm, Item, ChoiceData, StandardProcessing);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersRunningTimeRecordingParameters

&AtClient
Procedure RunningTimeRecordingParametersOnStartEdit(Item, NewRow, Copy)
	CurrentData = Items.RunningTimeRecordingParameters.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SourceSelectionOptions = New Array;
	SourceSelectionOptions.Add(New ChoiceParameter("SelectingSourceOfRunningTime", True));
	SourceTypes = "CatalogRef.Assets";
	Items.ParametersOfAccountingForDevelopmentsSource.TypeRestriction = New TypeDescription(SourceTypes);
	Items.ParametersOfAccountingForDevelopmentsSource.ChoiceParameters = New FixedArray(SourceSelectionOptions);
	Return; // there is an empty handler in the SC

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfDepreciationComponentSubAssets

&AtClient
Procedure ListOfDepreciationComponentSubAssetsSelection(Item, RowSelected, Field, StandardProcessing)

	CurrentData = Items.ListOfDepreciationComponentSubAssets.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ShowValue(, CurrentData.SubAssetComponent);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure Attachable_OnExecuteCommand(Command)

	AssetsClientLocalization.OnExecuteCommand(Command, ThisForm);

EndProcedure

&AtClient
Procedure PerformAFillInCheck(Command)
	Cancel = False;
	ClearMessages();
	PerformFillCheckOnServer(Cancel);
	If Not Cancel Then
		
		ShowUserNotification(
			NStr("vi = 'Đã thực hiện kiểm tra';
				|ru = 'Проверка выполнена';
				|en = 'Check complete'; fa = 'بررسی تکمیل شد';
				|it = 'Verifica effettuata';
				|pl = 'Weryfikacja wykonana';
				|tr = 'Kontrol tamamlandı'"),
			,
			NStr("vi = 'Không tìm thấy chi tiết lỗi điền';
				|ru = 'Ошибок заполнения реквизитов не обнаружено';
				|en = 'No errors were detected when filling out the attributes'; fa = 'No errors were detected when filling out the attributes';
				|it = 'Errori di riempimento dei requisiti non rilevati';
				|pl = 'Nie wykryto błędów wypełnienia atrybutów';
				|tr = 'Özniteliklerin doldurulmasında herhangi bir hata tespit edilmedi'"),
			PictureLib.Information32);
		
	EndIf;
	Return; // Empty handler for UT and KA
	
EndProcedure

&AtClient
Procedure SetTheStatusInOperation(Command)
	
	CheckCorrectnessWhenSaving = True;
	SetNewStatusAndRecord(StatusInOperation);
	
EndProcedure

&AtClient
Procedure SetTheLiquidatedStatus(Command)
	
	CheckCorrectnessWhenSaving = True;
	SetNewStatusAndRecord(StatusEliminated);
	
EndProcedure

&AtClient
Procedure SetTheStatusToBeEdited(Command)
	
	SetNewStatusAndRecord(TheStatusIsBeingEdited);
	
EndProcedure

&AtClient
Procedure FillInInventoryNumber(Command)
	
	Object.AssetID = Object.Code;
	
EndProcedure

&AtClient
Procedure BusinessAreaHistory(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("FixedAsset", Object.Ref);
	FormParameters.Insert("AttributeName", "LineOfBusiness");
	OpenForm("Catalog.Assets.Form.ChangeHistory", FormParameters, ThisForm);
	
EndProcedure

#Region StandardSubsystems

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	LockedAttributes = ObjectAttributesLockClient.Attributes(ThisObject);
	If LockedAttributes.Count() > 0 Then
		FormParameters = New Structure;
		FormParameters.Insert("Ref", Object.Ref);
		FormParameters.Insert("LockedAttributes", LockedAttributes);
		OpenForm(
			"Catalog.Assets.Form.AttributeUnlocking",
			FormParameters,
			ThisObject);
	Else
		ObjectAttributesLockClient.ShowAllVisibleAttributesUnlockedWarning();
	EndIf;
	
EndProcedure

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#EndRegion

#Region Private

#Region Other

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, NotificationParameters) Export

	Var ActionParameters;
	
	If NotificationParameters.ServerCallRequired_ Then
		WhenYouChangeDetailsOfCompletionOnServer(TagName, NotificationParameters.ProcessingParameters);
	EndIf;
	
	If Not NotificationParameters.ServerCallRequired_ Then
		If NotificationParameters.ProcessingParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
			ConfigureDependentFormElements(ThisForm, ActionParameters);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenYouChangeDetailsOfCompletionOnServer(TagName, AdditionalParameters)
	
	Var ActionParameters;
	
	AssetsLocalization.OnChangeAttribute(TagName, ThisForm, AdditionalParameters);
	
	If AdditionalParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElements(ThisForm, ActionParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	RefreshFormTitle();
	
	ObjectOfOperationIsTakenIntoAccount = NonCurrentAssets.ObjectOfOperationIsTakenIntoAccount(Object.Ref);
	
	UseProduction = False;
	UseRMManagement = False;
	UseProduction = GetFunctionalOption("UseProduction");
	UseRMManagement = GetFunctionalOption("UseRMManagement");
	If Not GetFunctionalOption("UseLocal") Then
		Items.DecorationAndRealEstate.Visible = False;
	EndIf;
	
	If Not NonCurrentAssetsInternal.ComplianceCAAccountingIsKept() Then
		Items.SceneryDevaluationTa.Visible = False;
		Items.DecorationImpairmentPD.Visible = False;
		Items.SceneryDepreciationOfTD.Visible = False;
	EndIf;
	
	If Not GetFunctionalOption("UseBusinessUnits") Then
		Items.RMBusinessUnit.Visible = False;
	EndIf;

	UseFixedAssetImpairment = GetFunctionalOption("UseFixedAssetImpairment");
	
	Items.GroupImpairment.Visible = UseFixedAssetImpairment;
	Items.ListOfUnitsComponentsOfDepreciationGroupImpairment.Visible = UseFixedAssetImpairment;
	
	ClassificationDM4 = Number(Object.HouseholdObject);
	
	StatusInOperation = Enums.AssetStatuses.InOperation;
	StatusEliminated = Enums.AssetStatuses.Disposed;
	TheStatusIsBeingEdited = Enums.AssetStatuses.IsBeingEdited;
	CheckCorrectnessWhenSaving = False;
	ErrorsInSubnodes = False;
	
	Items.DescriptionFull.ChoiceList.Clear();
	Items.DescriptionFull.ChoiceList.Add(Object.Description);
	
	FillInDisplayParameters(Object);
	FillInParametersForAccountingForDevelopments(Object.RunningTimeRecordingParameters, Object.Class);
	ConfigureFormElementsByObjectClass();
	FillInAccountingInformation();
	
	ReadPeriodicDetails();
	
	AssetsLocalization.OnReadCreateAtServer(ThisForm);
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtServer
Procedure WhenChangingFADocuments()

	ObjectOfOperationIsTakenIntoAccount = NonCurrentAssets.ObjectOfOperationIsTakenIntoAccount(Object.Ref);

	SetVisibilityOfInputCommandsBasedOn_();
	FillInAccountingInformation();
	ReadPeriodicDetails();
	
EndProcedure
 
&AtServer
Procedure SetVisibilityOfInputCommandsBasedOn_()

	SettingsAddress = ThisForm.AttachableCommandsParameters.CommandsTableAddress;
	CommandsTable = GetFromTempStorage(SettingsAddress);
	
	If GetFunctionalOption("UseNonCurrentAssets2_4") Then
	
		If ValueIsFilled(Object.Ref) Then
			
			InitialInformation = Catalogs.Assets.InitialInformation(Object.Ref);
			
			ChoiceOfReflectionInAccountsIsAvailable = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
			
			CanBeTakenIntoAccount = ChoiceOfReflectionInAccountsIsAvailable
									And (InitialInformation.CommissioningDateAC = '000101010000'
										Or InitialInformation.CommissioningDateMA = '000101010000')
								Or Not ChoiceOfReflectionInAccountsIsAvailable
									And InitialInformation.CommissioningDateMA = '000101010000';
								
			PostedInFinancialAccounting = InitialInformation.CommissioningDateAC <> '000101010000'
								Or InitialInformation.CommissioningDateMA <> '000101010000';
								
			EnteredInOffBalanceAccounting = 
				InitialInformation.BUState = Enums.FixedAssetsStates.EnteredInOffBalanceAccounting
				Or InitialInformation.StateOfTheUU = Enums.FixedAssetsStates.EnteredInOffBalanceAccounting;
				
		Else
			CanBeTakenIntoAccount = False;
			PostedInFinancialAccounting = False;
			EnteredInOffBalanceAccounting = False;
		EndIf;
		
		RentalAvailable = (Object.OSType = Enums.FATypes.Asset);
		
		If AccessRight("Insert", Metadata.Documents.FixedAssetsInitialRecognition2_4) Then
			NonCurrentAssetsInternal.SetVisibilityOfInputCommandBasedOn(
				Items, "FixedAssetsInitialRecognition2_4", CommandsTable, CanBeTakenIntoAccount);
		EndIf; 
		
		If AccessRight("Insert", Metadata.Documents.ChangeFixedAssetFinancialDetails2_4) Then
			NonCurrentAssetsInternal.SetVisibilityOfInputCommandBasedOn(
				Items, "ChangeFixedAssetFinancialDetails2_4", CommandsTable, PostedInFinancialAccounting And Not EnteredInOffBalanceAccounting);
		EndIf; 
		
		If AccessRight("Insert", Metadata.Documents.FATransfer2_4) Then
			NonCurrentAssetsInternal.SetVisibilityOfInputCommandBasedOn(
				Items, "FATransfer2_4", CommandsTable, PostedInFinancialAccounting);
		EndIf; 
		
		If AccessRight("Insert", Metadata.Documents.DisposeFixedAssets2_4) Then
			NonCurrentAssetsInternal.SetVisibilityOfInputCommandBasedOn(
				Items, "DisposeFixedAssets2_4", CommandsTable, PostedInFinancialAccounting And Not EnteredInOffBalanceAccounting);
		EndIf; 
		
		If AccessRight("Insert", Metadata.Documents.FixedAssetsCostAdditions2_4) Then
			NonCurrentAssetsInternal.SetVisibilityOfInputCommandBasedOn(
				Items, "FixedAssetsCostAdditions2_4", CommandsTable, PostedInFinancialAccounting And Not EnteredInOffBalanceAccounting);
		EndIf; 
		
		If AccessRight("Insert", Metadata.Documents.PreparingForFixedAssetSale2_4) Then
			NonCurrentAssetsInternal.SetVisibilityOfInputCommandBasedOn(
				Items, "PreparingForFixedAssetSale2_4", CommandsTable, PostedInFinancialAccounting And Not EnteredInOffBalanceAccounting);
		EndIf; 
		
		If AccessRight("Insert", Metadata.Documents.FARevaluation2_4) Then
			NonCurrentAssetsInternal.SetVisibilityOfInputCommandBasedOn(
				Items, "FARevaluation2_4", CommandsTable, PostedInFinancialAccounting And Not EnteredInOffBalanceAccounting);
		EndIf; 
	
		If AccessRight("Insert", Metadata.Documents.SplitFixedAssets) Then
			NonCurrentAssetsInternal.SetVisibilityOfInputCommandBasedOn(
				Items, "SplitFixedAssets", CommandsTable, PostedInFinancialAccounting And Not EnteredInOffBalanceAccounting);
		EndIf; 
	
		If AccessRight("Insert", Metadata.Documents.FixedAssetCostAndDepreciationAdjustment) Then
			NonCurrentAssetsInternal.SetVisibilityOfInputCommandBasedOn(
				Items, "FixedAssetCostAndDepreciationAdjustment", CommandsTable, PostedInFinancialAccounting);
		EndIf; 
	
		If AccessRight("Insert", Metadata.Documents.VendorInvoiceLeasedAssets) Then
			NonCurrentAssetsInternal.SetVisibilityOfInputCommandBasedOn(
				Items, "VendorInvoiceLeasedAssets", CommandsTable, PostedInFinancialAccounting And RentalAvailable);
		EndIf; 

		If AccessRight("Insert", Metadata.Documents.LeaseTermination) Then
			NonCurrentAssetsInternal.SetVisibilityOfInputCommandBasedOn(
				Items, "LeaseTermination", CommandsTable, PostedInFinancialAccounting And RentalAvailable);
		EndIf; 

		If AccessRight("Insert", Metadata.Documents.LeaseTermAdjustment) Then
			NonCurrentAssetsInternal.SetVisibilityOfInputCommandBasedOn(
				Items, "LeaseTermAdjustment", CommandsTable, PostedInFinancialAccounting And RentalAvailable);
		EndIf;
		 
	EndIf; 
	
	AssetsLocalization.SetVisibilityOfInputCommandsBasedOn_(ThisForm, CommandsTable);
	
EndProcedure

&AtClient
Procedure SetNewStatusAndRecord(Status)
	
	ClearMessages();
	
	CurrentStatus = Object.Status;
	Object.Status = Status;
	
	If Not Write() Then
		Object.Status = CurrentStatus;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDisplayParameters(ObjectToFillIn_)
	
	SetPrivilegedMode(True);
	
	SavedObjectStatus = ObjectToFillIn_.Status;
	
	IsBeingEdited = (Not UseRMManagement) Or (Not ValueIsFilled(ObjectToFillIn_.Status) Or ObjectToFillIn_.Status = TheStatusIsBeingEdited);
	UseOfSubclasses = False;
	If UseRMManagement And ValueIsFilled(Object.Class) Then
		UseOfSubclasses = Common.ObjectAttributeValue(ObjectToFillIn_.Class, "UseOfSubclasses");
		AttributeSet.Load(CompositionOfDetailsOfClassOfObjectOfOperation());
	Else
		UseOfSubclasses = False;
		AttributeSet.Load(Catalogs.Assets.CompositionOfDetailsOfObjectOfOperation());
	EndIf;
	SetPrivilegedMode(False);
	
	StatusChangeIsAvailable = AccessRight("Update", Metadata.Catalogs.Assets);
	
EndProcedure

&AtServer
Procedure ConfigureFormElementsByObjectClass()
	
	For Each Attribute In AttributeSet Do
		
		Name = TrimAll(Attribute.Name);
		
		Item = Items.Find(Name);
		If Item <> Undefined Then
			
			Item.AutoMarkIncomplete = Attribute.RequiredForFilling;
			Item.MarkIncomplete = False;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure PerformFillCheckOnServer(Cancel = False)
	
	CheckParameters = Catalogs.Assets.FillVerificationParameters();
	CheckParameters.Form = ThisForm;
	CheckParameters.Report_Errors = False;
	
	Catalogs.Assets.CheckFillingOfObjectOfOperation(Object, CheckParameters, Cancel);
	
	If Cancel Then
		
		ErrorsInSubnodes = CheckParameters.NodeValidationFailure;
		
		Assets.ReportFillVerificationErrors(CheckParameters.ErrorStream);
		
	EndIf;
	
	If ErrorsInSubnodes Then
		
		Common.MessageToUser(
			NStr("vi = 'Có lỗi điền vào chi tiết phụ thuộc';
				|ru = 'Есть ошибки заполнения подчиненных узлов';
				|en = 'Errors occurred while populating subassemblies'; fa = 'Errors occurred while populating subassemblies';
				|it = 'Ci sono errori nella compilazione dei nodi subordinati';
				|pl = 'Istnieją błędy wypełnienia węzłów podporządkowanych';
				|tr = 'Bağlı alt varlıkların doldurulmasında hatalar var'"),,
			"ErrorsInSubnodes");
		
		NodeWithErrors = Catalogs.SubAssets.EmptyRef();
		If CheckParameters.NodeVerificationParameters.ErrorStream.ErrorCounter.Count() = 1 Then
			For Each ErrorObject_ In CheckParameters.NodeVerificationParameters.ErrorStream.ErrorCounter Do
				NodeWithErrors = ErrorObject_.Key;
			EndDo;
		EndIf;
		
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "ErrorsInSubnodes");
	
EndProcedure

&AtServer
Function CompositionOfDetailsOfClassOfObjectOfOperation()
	
	Query = New Query(
		"SELECT
		|	CAST(AttributeSet.Name AS STRING(255)) AS Name,
		|	CAST(AttributeSet.Synonym AS STRING(255)) AS Synonym,
		|	CAST(AttributeSet.RequiredForFilling AS BOOLEAN) AS RequiredForFilling,
		|	CAST(AttributeSet.RequiredForViewOnly AS BOOLEAN) AS RequiredForViewOnly
		|INTO ObjectsAttributes
		|FROM
		|	&ItemDetails__ AS AttributeSet
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Attributes.AttributeName AS Name,
		|	Attributes.RequiredForFilling AS RequiredForFilling
		|INTO DetailsOfClassObjects
		|FROM
		|	Catalog.MaintenanceSchemes.AttributesForControl AS Attributes
		|WHERE
		|	Attributes.Ref = &Class
		|	AND Attributes.AttributeName IN (SELECT ObjectsAttributes.Name FROM ObjectsAttributes AS ObjectsAttributes)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(Attributes.Name, DetailsForObjectControl.Name) AS Name,
		|	ISNULL(Attributes.RequiredForFilling, FALSE) AS RequiredForFilling
		|FROM
		|	DetailsOfClassObjects AS Attributes
		|		FULL JOIN ObjectsAttributes AS DetailsForObjectControl
		|		ON Attributes.Name = DetailsForObjectControl.Name"
	);
	Query.SetParameter("ItemDetails__", Catalogs.Assets.CompositionOfDetailsOfObjectOfOperation());
	Query.SetParameter("Class", Object.Class);
	
	Return Query.Execute().Unload();
	
EndFunction

&AtServer
Procedure FillInParametersForAccountingForDevelopments(PopulationTable, FillingClass)
	
	Query = New Query(
		"SELECT
		|	PopulationTable.RunningTimeValue,
		|	PopulationTable.AssignedResource,
		|	PopulationTable.SourceOfParameter
		|INTO PopulationTable
		|FROM
		|	&PopulationTable AS PopulationTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OperatingTimeIndicatorsByClassification.RunningTimeValue AS RunningTimeValue,
		|	PopulationTable.AssignedResource AS AssignedResource,
		|	PopulationTable.SourceOfParameter AS SourceOfParameter,
		|	OperatingTimeIndicatorsByClassification.CalculateResidualLifetime AS FillOutTheAssignedResource,
		|	OperatingTimeIndicatorsByClassification.RegistrationMethod AS RegistrationMethod,
		|	OperatingTimeIndicatorsByClassification.RegisterBySource AS FillInTheSource
		|FROM
		|	Catalog.MaintenanceSchemes.RunningTimeValues AS OperatingTimeIndicatorsByClassification
		|		LEFT JOIN PopulationTable AS PopulationTable
		|		ON OperatingTimeIndicatorsByClassification.RunningTimeValue = PopulationTable.RunningTimeValue
		|WHERE
		|	OperatingTimeIndicatorsByClassification.Ref = &Class
		|	AND (OperatingTimeIndicatorsByClassification.CalculateResidualLifetime
		|			OR OperatingTimeIndicatorsByClassification.RegisterBySource)
		|
		|ORDER BY
		|	OperatingTimeIndicatorsByClassification.LineNumber");
	Query.SetParameter("PopulationTable", PopulationTable.Unload(, "RunningTimeValue, AssignedResource, SourceOfParameter"));
	Query.SetParameter("Class", FillingClass);
	
	RunningTimeRecordingParameters.Load(Query.Execute().Unload());
	
EndProcedure

&AtClient
Procedure Attachable_UpdateForm()
	
	If ThisForm.IsInputAvailable() Then
		
		DetachIdleHandler("Attachable_UpdateForm");
		
		ThisForm.Read();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RunningTimeRecordingParametersAssignedResource.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RunningTimeRecordingParameters.FillOutTheAssignedResource");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không bắt buộc>';
													|ru = '< не требуется >';
													|en = '< not required >'; fa = '< not required >';
													|it = '< non si necessita >';
													|pl = '< nie jest wymagane >';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ParametersOfAccountingForDevelopmentsSource.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RunningTimeRecordingParameters.FillInTheSource");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không bắt buộc>';
													|ru = '< не требуется >';
													|en = '< not required >'; fa = '< not required >';
													|it = '< non si necessita >';
													|pl = '< nie jest wymagane >';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RunningTimeRecordingParametersAssignedResource.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RunningTimeRecordingParameters.FillOutTheAssignedResource");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RunningTimeRecordingParameters.AssignedResource");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ParametersOfAccountingForDevelopmentsSource.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RunningTimeRecordingParameters.FillInTheSource");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RunningTimeRecordingParameters.SourceOfParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	AssetsLocalization.SetConditionalAppearance(ThisForm);
	
EndProcedure

&AtServer
Procedure FillInAccountingInformation()

	If Not Catalogs.Assets.ThereAreRightsToReadInformation() Then
		Items.DetailsInfoPage.Visible = False;
		Return;
	EndIf;
	
	InformationAboutAccounting = Catalogs.Assets.InformationAboutAccounting(Object.Ref);
	
	If InformationAboutAccounting = Undefined Then
		Items.PagesFAInformation.CurrentPage = Items.PageInfoOnNotRecognized;
		Items.PageInfoOnRecognized.Visible = False;
		Items.ListOfDepreciationComponentSubAssets.Visible = False;
		Return;
	EndIf;
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Catalog.Assets.Form.ItemForm.FillInAccountingInformation");
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(InformationAboutAccounting.Organization);
	
	ComplianceCAAccountingIsKept = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	If ComplianceCAAccountingIsKept Then
		Items.DecorationTitleBOO.Title = StrTemplate(NStr("vi = 'KTDN (%1):';
															|ru = 'БУ (%1):';
															|en = 'LA (%1):'; fa = 'LA (%1):';
															|it = 'Contabilità (%1):';
															|pl = 'EK (%1):';
															|tr = 'Genel Muhasebe (%1):'"), String(ComplCurrency));
		Items.DecorationTitleUU.Title = StrTemplate(NStr("vi = 'KTQT (%1):';
														|ru = 'УУ (%1):';
														|en = 'MA (%1):'; fa = 'MA (%1):';
														|it = 'Contabilità Gestionale (%1):';
														|pl = 'EZ (%1):';
														|tr = 'Yönetim Muhasebesi(%1):'"), String(CurrencyOfMan));
	Else
		Items.DecorationTitleBOO.Title = StrTemplate(NStr("vi = 'Tài chính (%1):';
															|ru = 'Регл. (%1):';
															|en = 'Local (%1):'; fa = 'Local (%1):';
															|it = 'Regol. (%1):';
															|pl = 'Reg. (%1):';
															|tr = 'Yerel (%1):'"), String(ComplCurrency));
		Items.DecorationTitleUU.Title = StrTemplate(NStr("vi = 'Quản trị (%1):';
														|ru = 'Упр. (%1):';
														|en = 'Mgmt (%1):'; fa = 'Mgmt (%1):';
														|it = 'Gest. (%1):';
														|pl = 'Zarz. (%1):';
														|tr = 'Yönetim (%1):'"), String(CurrencyOfMan));
	EndIf; 
	
	If Not ComplianceCAAccountingIsKept Then
		
		Items.DecorationTitleWELL.Visible = False;
		Items.DecorationTitlePR.Visible = False;
		Items.DecorationTitleVR.Visible = False;
		
		If CurrencyOfMan = ComplCurrency
			And Not AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(InformationAboutAccounting.Organization) Then
			
			Items.DecorationTitleBOO.Visible = False;
			Items.DecorationTitleUU.Visible = False;
			Items.GroupResidualValueHeading.Visible = False;
			Items.GroupAccumulatedDepreciationHeading.Visible = False;
			Items.GroupImpairmentHeading.Visible = False;
			Items.GroupCurrentValueHeading.Visible = False;
			
			Items.ReplacementACCost.Visible = False;
			Items.AccumulatedDepreciationAccounting.Visible = False;
			Items.ImpairmentAC.Visible = False;
			Items.ACResidualValue.Visible = False;
			
			Items.ReplacementCostOfTheUU.Visible = False;
			Items.AccumulatedDepreciationManagementAccounting.Visible = False;
			Items.ImpairmentMA.Visible = False;
			Items.NetBookValueMan.Visible = False;
			
			Items.ListOfDepreciationComponentSubAssetsAccountingForLocal.Visible = False;
			Items.ListOfDepreciationComponentSubAssetsManAccounting.Visible = False;
			Items.ListOfDepreciationComponentSubAssetsLocalCost.Visible = False;
			Items.ListOfDepreciationComponentSubAssetsDepreciationLocal.Visible = False;
			Items.ListOfDepreciationComponentSubAssetsImpairmentLocalAssets.Visible = False;
			Items.ListOfDepreciationComponentSubAssetsNetBookValueLocal.Visible = False;
			
		EndIf; 
		
		// Hide elements of the accounting system.
		Items.InformationAcceptedForAccounting2.Visible = False;
		Items.InformationTermOfUse2.Visible = False;
		Items.InformationRemovedFromTheRegister2.Visible = False;
		
		Items.GroupCurrentValueCFHeader.Visible = False;
		Items.GroupNetBookValueCFHeading.Visible = False;
		Items.GroupAccumulatedDepreciationHeadingCF.Visible = False;
		Items.RegisteredInPlatonSystemRegistry.Visible = False;
		
	EndIf;
	
	CostAndDepreciation = NonCurrentAssets.CostAndDepreciationOfFA(Object.Ref);
	
	Items.PagesFAInformation.CurrentPage = Items.PageInfoOnRecognized;
	
	PresentationOfInformation = Catalogs.Assets.PresentationOfAccountingInformation(InformationAboutAccounting, CostAndDepreciation);
	
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.InformationAcceptedForAccounting1, PresentationOfInformation.InformationAcceptedForAccounting1);
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.InformationAcceptedForAccounting3, PresentationOfInformation.InformationAcceptedForAccounting3);
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.InformationTermOfUse1, PresentationOfInformation.InformationTermOfUse1);
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.InformationTermOfUse3, PresentationOfInformation.InformationTermOfUse3);
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.InformationLiquidationValueOfRegl, PresentationOfInformation.InformationLiquidationValueOfRegl);
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.InformationLiquidationValue, PresentationOfInformation.InformationLiquidationValue);
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.InformationRemovedFromTheRegister1, PresentationOfInformation.InformationRemovedFromTheRegister1);
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.InformationRemovedFromTheRegister3, PresentationOfInformation.InformationRemovedFromTheRegister3);
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.HFCInformation, PresentationOfInformation.HFCInformation);
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.PartnerInformation, PresentationOfInformation.PartnerInformation);
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.InformationCounterparty, PresentationOfInformation.InformationCounterparty);
	NonCurrentAssetsClientServer.FillInItemDetails_(Items.InformationContract, PresentationOfInformation.InformationContract);
		
	HeaderInformation_ = StrTemplate(NStr("vi = 'Địa điểm (thông tin từ %1)';
											|ru = 'Местонахождение (сведения от %1)';
											|en = 'Location (information from %1)'; fa = 'Location (information from %1)';
											|it = 'Posizione (informazioni da %1)';
											|pl = 'Lokalizacja (informacje z dn. %1)';
											|tr = 'Yerleşim (%1 üzerindeki bilgiler)'"), Format(InformationAboutAccounting.LocationInformationPeriod, "DLF=D"));
	Items.GroupLocation.Title = HeaderInformation_;
	
	NonCurrentAssetsClientServer.FillInItemDetails_(
		Items.InformationLocationCompany, PresentationOfInformation.InformationLocationCompany);
		
	NonCurrentAssetsClientServer.FillInItemDetails_(
		Items.InformationLocationDepartment, PresentationOfInformation.InformationLocationDepartment);
		
	NonCurrentAssetsClientServer.FillInItemDetails_(
		Items.InformationInventoryCustodianLocation, PresentationOfInformation.InformationInventoryCustodianLocation);
		
	NonCurrentAssetsClientServer.FillInItemDetails_(
		Items.InformationLocationAddress, PresentationOfInformation.InformationLocationAddress);
		
	NonCurrentAssetsClientServer.FillInItemDetails_(
		Items.InformationReplacementCost, PresentationOfInformation.InformationReplacementCost);
		
	NonCurrentAssetsClientServer.FillInItemDetails_(
		Items.InformationAccumulatedDepreciation, PresentationOfInformation.InformationAccumulatedDepreciation);
		
	NonCurrentAssetsClientServer.FillInItemDetails_(
		Items.InformationImpairment, PresentationOfInformation.InformationImpairment);
		
	NonCurrentAssetsClientServer.FillInItemDetails_(
		Items.InformationResidualValue, PresentationOfInformation.InformationResidualValue);

	#Region Amounts
	
	ReplacementACCost = CostAndDepreciation.LocalCost;
	ReplacementCostOfTheUU = CostAndDepreciation.Cost;
	AccumulatedDepreciationAccounting = CostAndDepreciation.DepreciationLocal;
	AccumulatedDepreciationManagementAccounting = CostAndDepreciation.Depreciation;
	ImpairmentAC = CostAndDepreciation.ImpairmentLocalAssets;
	ImpairmentMA = CostAndDepreciation.ImpairmenMan;
	ACResidualValue = CostAndDepreciation.LocalCost - CostAndDepreciation.DepreciationLocal - CostAndDepreciation.ImpairmentLocalAssets;
	NetBookValueMan = CostAndDepreciation.Cost - CostAndDepreciation.Depreciation - CostAndDepreciation.ImpairmenMan;
	
	Items.GroupCurrentValueHeading.Title       = NStr("vi = 'Chi phí thay thế:';
														|ru = 'Восстановительная стоимость:';
														|en = 'Replacement cost:'; fa = 'Replacement cost:';
														|it = 'Costi recuperabili:';
														|pl = 'Koszt odtworzenia:';
														|tr = 'Yenileme değeri:'");
	Items.GroupAccumulatedDepreciationHeading.Title = NStr("vi = 'Khấu hao lũy kế:';
															|ru = 'Накопленная амортизация:';
															|en = 'Accumulated depreciation:'; fa = 'Accumulated depreciation:';
															|it = 'Ammortamenti accumulati:';
															|pl = 'Skumulowana amortyzacja:';
															|tr = 'Birikmiş amortisman:'");
	Items.GroupImpairmentHeading.Title            = NStr("vi = 'Giảm giá:';
														|ru = 'Обесценение:';
														|en = 'Impairment:'; fa = 'Impairment:';
														|it = 'Svalutazione:';
														|pl = 'Utrata wartości:';
														|tr = 'Değer kaybı:'");
	Items.GroupResidualValueHeading.Title    = NStr("vi = 'Giá trị còn lại:';
													|ru = 'Остаточная стоимость:';
													|en = 'Net book value:'; fa = 'Net book value:';
													|it = 'Valore residuo:';
													|pl = 'Wartość rezydualna:';
													|tr = 'Net defter değeri:'");
	
	Items.CurrentValueGroup.ShowTitle        = False;
	Items.GroupAccumulatedDepreciation.ShowTitle  = False;
	Items.GroupImpairment.ShowTitle             = False;
	Items.GroupResidualValue_2.ShowTitle     = False;
	
	#EndRegion
	
	#Region ListOfDepreciationComponentSubAssets
	
	NumberOfComponentNodes = 0;
	
	If Object.OSType = PredefinedValue("Enum.FATypes.Asset")
		Or Object.OSType = PredefinedValue("Enum.FATypes.GroupFA") Then
		
		ListOfDepreciationComponentSubAssets.Clear();
		CostAndDepreciationOfComponentsComponents = NonCurrentAssets.CostAndDepreciationOfComponentsComponents(Object.Ref);
		For Each ComponentNodeCostString In CostAndDepreciationOfComponentsComponents Do
			
			ComponentNodeString = ListOfDepreciationComponentSubAssets.Add();
			FillPropertyValues(ComponentNodeString, ComponentNodeCostString);
			
			If ComplianceCAAccountingIsKept Then
				ComponentNodeString.AccountingForLocal = StrTemplate(NStr("vi = 'KTDN (%1)';
																			|ru = 'БУ (%1)';
																			|en = 'LA (%1)'; fa = 'LA (%1)';
																			|it = 'Contabilità (%1)';
																			|pl = 'EK (%1)';
																			|tr = 'Genel Muhasebe (%1):'"), String(ComplCurrency));
				ComponentNodeString.ManAccounting = StrTemplate(NStr("vi = 'KTQT (%1)';
																	|ru = 'УУ (%1)';
																	|en = 'MA (%1)'; fa = 'MA (%1)';
																	|it = 'Contabilità Gestionale (%1)';
																	|pl = 'EZ (%1)';
																	|tr = 'Yönetim Muhasebesi(%1):'"), String(CurrencyOfMan));
			Else
				ComponentNodeString.AccountingForLocal = StrTemplate(NStr("vi = 'Tài chính (%1)';
																			|ru = 'Регл. (%1)';
																			|en = 'Local (%1)'; fa = 'Local (%1)';
																			|it = 'Reg. (%1)';
																			|pl = 'Regl. (%1)';
																			|tr = 'Yerel (%1):'"), String(ComplCurrency));
				ComponentNodeString.ManAccounting = StrTemplate(NStr("vi = 'Quản trị (%1)';
																	|ru = 'Упр. (%1)';
																	|en = 'Mgmt (%1)'; fa = 'Mgmt (%1)';
																	|it = 'Gest. (%1)';
																	|pl = 'Zarz. (%1)';
																	|tr = 'Yönetim (%1):'"), String(CurrencyOfMan));
			EndIf; 
			
			NumberOfComponentNodes = NumberOfComponentNodes + 1;
			
		EndDo;
		
	EndIf;
	
	Items.ListOfDepreciationComponentSubAssets.Visible = (NumberOfComponentNodes <> 0);
	
	#EndRegion
	
	AssetsLocalization.FillInAccountingInformation(ThisForm, InformationAboutAccounting, PresentationOfInformation);
	AssetsLocalization.FillInCostAndDepreciation(ThisForm, InformationAboutAccounting, CostAndDepreciation);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, Val ChangedBankingDetails = "")

	Object = Form.Object;
	Items = Form.Items;
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	AuxiliaryAttributes = New Structure; 
	AuxiliaryAttributes.Insert("UseLocal", Form.UseLocal);
	AuxiliaryAttributes.Insert("UseRMManagement", Form.UseRMManagement);
	AuxiliaryAttributes.Insert("UseOfSubclasses", Form.UseOfSubclasses);
	AuxiliaryAttributes.Insert("UseProduction", Form.UseProduction);
	AuxiliaryAttributes.Insert("UseAccountingOfPreciousMaterial", Form.UseAccountingOfPreciousMaterial);	
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_ObjectsOfOperation(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
	
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters);
	EndIf;
	
	NonCurrentAssetsClientServerLocalization.ConfigureDependentFormElements_Objects_(
		Form, StructureOfChangedProps);
	
	If StructureOfChangedProps.Property("OSType")
		Or UpdateAll Then

		PropertyValue = 
			Object.OSType = PredefinedValue("Enum.FATypes.Asset")
			Or Object.OSType = PredefinedValue("Enum.FATypes.CapitalExpenditureInLeasedAssets");
		
		Items.DepreciationGroup.Visible = PropertyValue;

		//
		PropertyValue = 
			Object.OSType = PredefinedValue("Enum.FATypes.Asset");
		Items.ErrorsInSubnodes.Visible = PropertyValue;
	
		//
		PropertyValue = 
			(Object.OSType = PredefinedValue("Enum.FATypes.Asset")
				Or Object.OSType = PredefinedValue("Enum.FATypes.CapitalExpenditureInLeasedAssets"))
			And Form.UseLocal;
			
		Items.DecorationAndRealEstate.Visible = PropertyValue;
		
		If Object.OSType = PredefinedValue("Enum.FATypes.DepreciationComponent")
			Or Object.OSType = PredefinedValue("Enum.FATypes.Node") Then
			
			Items.InformationLocationDepartment.Visible = False;
			Items.InformationInventoryCustodianLocation.Visible = False;
			Items.InformationLocationAddress.Visible = False;
		EndIf;

		//
		PropertyValue = 
			(Object.OSType = PredefinedValue("Enum.FATypes.Asset")
				Or Object.OSType = PredefinedValue("Enum.FATypes.Node"))
			And Form.StatusChangeIsAvailable
			And Form.UseRMManagement;
		
		Items.SetTheStatusToBeEdited.Visible = PropertyValue;
		Items.SetTheStatusInOperation.Visible = PropertyValue;
		Items.SetTheLiquidatedStatus.Visible = PropertyValue;
		Items.CheckFilling.Visible = PropertyValue;
				
	EndIf;
	
	If StructureOfChangedProps.Property("OSType")
		Or StructureOfChangedProps.Property("ErrorsInSubnodes")
		Or UpdateAll Then

		PropertyValue = 
			Object.OSType = PredefinedValue("Enum.FATypes.Asset")
			And Form.ErrorsInSubnodes
			And Form.UseRMManagement;
			
		Items.DecorationPictureThereAreErrorsOfSubordinates.Visible = PropertyValue;
		
	EndIf;
	
	If StructureOfChangedProps.Property("Ref")
		Or StructureOfChangedProps.Property("OSType")
		Or UpdateAll Then
			
		If ValueIsFilled(Object.AssetID)
			And ValueIsFilled(Object.Ref) Then
	
			AllowedToChangeInvNumber = Not Form.ObjectOfOperationIsTakenIntoAccount;
		Else
			AllowedToChangeInvNumber = True;
		EndIf; 
		
		Items.AssetID.WarningOnEditRepresentation = 
			?(AllowedToChangeInvNumber, WarningOnEditRepresentation.DontShow, WarningOnEditRepresentation.Show);
			
		Items.FillInInventoryNumber.Visible = 
			AllowedToChangeInvNumber
			And (Object.OSType = PredefinedValue("Enum.FATypes.Asset")
				Or Object.OSType = PredefinedValue("Enum.FATypes.Node")
				Or Object.OSType = PredefinedValue("Enum.FATypes.DepreciationComponent")
				Or Object.OSType = PredefinedValue("Enum.FATypes.CapitalExpenditureInLeasedAssets"));
		
	EndIf;
	
	If StructureOfChangedProps.Property("Ref")
		Or StructureOfChangedProps.Property("Class")
		Or StructureOfChangedProps.Property("OSType")
		Or UpdateAll Then
			
		PropertyValue = Not Form.IsBeingEdited;
		
		Items.DateOfLastEdit.ReadOnly = PropertyValue;
		Items.Parent.ReadOnly = PropertyValue;
		Items.Code.ReadOnly = PropertyValue;
		Items.Description.ReadOnly = PropertyValue;
		Items.DescriptionFull.ReadOnly = PropertyValue;
		Items.LongDesc.ReadOnly = PropertyValue;
		Items.WorkCenters.ReadOnly = PropertyValue;
		Items.RunningTimeRecordingParameters.ReadOnly = PropertyValue;
		Items.GroupAdditionalAttributes.ReadOnly = PropertyValue;
		
		//
		Items.WorkCentersPage.Visible = Form.UseProduction And Form.UseRMManagement;
		
		//
		Items.SetTheStatusToBeEdited.Enabled = 
			Object.Status <> PredefinedValue("Enum.AssetStatuses.IsBeingEdited");
		
		Items.SetTheStatusInOperation.Enabled = 
			Object.Status <> PredefinedValue("Enum.AssetStatuses.InOperation");
			
		Items.SetTheLiquidatedStatus.Enabled = 
			Object.Status <> PredefinedValue("Enum.AssetStatuses.Disposed");
		
		//
		Items.RunningTimeRecordingParameters.Visible = Form.RunningTimeRecordingParameters.Count() > 0;
	
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadPeriodicDetails()

	If GetFunctionalOption("UseFixedAssetAccountingByActivities") Then
		
		QueryText = 
		"SELECT
		|	FixedAssetsAccountingProcedureSliceLast.LineOfBusiness AS LineOfBusiness
		|FROM
		|	InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
		|			, 
		|			CorrectionDate = DATETIME(1,1,1)
		|				AND FixedAsset = &FixedAsset) AS FixedAssetsAccountingProcedureSliceLast";
		
		Query = New Query(QueryText);
		Query.SetParameter("FixedAsset", Object.Ref);
		
		SetPrivilegedMode(True);
		Result = Query.Execute();
		SetPrivilegedMode(False);
		
		Selection = Result.Select();
		
		If Selection.Next() Then
			
			LineOfBusiness = Selection.LineOfBusiness;
			ChangeHistory = Catalogs.Assets.HistoryOfChangingProps(Object.Ref, "LineOfBusiness");
			Items.BusinessAreaHistory.Visible = (ChangeHistory.Count() <> 0);
			
		Else
			LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
			Items.BusinessAreaHistory.Visible = False;
		EndIf;
		
	EndIf; 

	AssetsLocalization.ReadPeriodicDetails(ThisObject);
	
EndProcedure

&AtServer
Procedure RefreshFormTitle()

	If Object.OSType = Enums.FATypes.GroupFA Then
		
		Title = 
			?(ValueIsFilled(Object.Ref),
				StrTemplate(NStr("vi = '%1 (TSCĐ theo nhóm)';
								|ru = '%1 (Групповое ОС)';
								|en = '%1 (Group fixed assets)'; fa = '%1 (Group fixed assets)';
								|it = '%1 (Gruppo di cespiti)';
								|pl = '%1 (Grupowy ŚT)';
								|tr = '%1(Sabit Kıymet grubu)'"), Object.Description),
				NStr("vi = 'TSCĐ theo nhóm (tạo mới)';
					|ru = 'Групповое ОС (создание)';
					|en = 'Group fixed assets (create)'; fa = 'Group fixed assets (create)';
					|it = 'Gruppo di cespiti (creazione)';
					|pl = 'Grupowy ŚT (tworzenie)';
					|tr = 'Sabit Kıymet grubu (oluşturma)'"));
				
	ElsIf Object.OSType = Enums.FATypes.Node Then
		
		Title = 
			?(ValueIsFilled(Object.Ref),
				StrTemplate(NStr("vi = '%1 (Nút)';
								|ru = '%1 (Узел)';
								|en = '%1 (Sub-asset)'; fa = '%1 (Sub-asset)';
								|it = '%1 (Nodo)';
								|pl = '%1 (Węzeł)';
								|tr = '%1 (alt varlık)'"), Object.Description),
				NStr("vi = 'Nút (tạo mới)';
					|ru = 'Узел (создание)';
					|en = 'Sub-asset (create)'; fa = 'Sub-asset (create)';
					|it = 'Nodo (creazione)';
					|pl = 'Węzeł (tworzenie)';
					|tr = 'Alt varlık (oluşturma)'"));
				
	ElsIf Object.OSType = Enums.FATypes.DepreciationComponent Then
		
		Title = 
			?(ValueIsFilled(Object.Ref),
				StrTemplate(NStr("vi = '%1 (Thành phần khấu hao)';
								|ru = '%1 (Компонент амортизации)';
								|en = '%1 (Depreciation component)'; fa = '%1 (Depreciation component)';
								|it = '%1 (Componente ammortamento)';
								|pl = '%1 (Komponent amortyzacji)';
								|tr = '%1 (amortisman bileşeni)'"), Object.Description),
				NStr("vi = 'Thành phần khấu hao (tạo mới)';
					|ru = 'Компонент амортизации (создание)';
					|en = 'Depreciation component (create)'; fa = 'Depreciation component (create)';
					|it = 'Componente di ammortamento (creazione)';
					|pl = 'Komponent amortyzacji (tworzenie)';
					|tr = 'Amortisman bileşeni (oluştur)'"));
				
	ElsIf Object.OSType = Enums.FATypes.CapitalExpenditureInLeasedAssets Then
		
		Title = 
			?(ValueIsFilled(Object.Ref),
				StrTemplate(NStr("vi = '%1 (Các khoản đầu tư vốn vào tài sản thuê)';
								|ru = '%1 (Кап. вложения в арендованное имущество)';
								|en = '%1 (Capital expenditure in leased assets)'; fa = '%1 (Capital expenditure in leased assets)';
								|it = '%1 (Кап. вложения в арендованное имущество)';
								|pl = '%1 (Capital expenditure in leased assets)';
								|tr = '%1 (Kiralanan mülke yapılan sermaye yatırımı)'"), Object.Description),
				NStr("vi = 'Các khoản đầu tư vốn vào tài sản thuê (tạo mới)';
					|ru = 'Кап. вложения в арендованное имущество (создание)';
					|en = 'Capital expenditure in leased assets (Create)'; fa = 'Capital expenditure in leased assets (Create)';
					|it = 'Кап. вложения в арендованное имущество (создание)';
					|pl = 'Capital expenditure in leased assets (Create)';
					|tr = 'Kiralanan mülke yapılan sermaye yatırımı (yarat)'"));
				
	Else
		
		Title = 
			?(ValueIsFilled(Object.Ref),
				StrTemplate(NStr("vi = '%1 (Đối tượng sử dụng)';
								|ru = '%1 (Объект эксплуатации)';
								|en = '%1 (Asset)'; fa = '%1 (Asset)';
								|it = '%1 (Oggetto di lavorazione)';
								|pl = '%1 (Obiekt eksploatacji)';
								|tr = '%1 (Varlık)'"), Object.Description),
				NStr("vi = 'Đối tượng sử dụng (tạo mới)';
					|ru = 'Объект эксплуатации (создание)';
					|en = 'Asset (create)'; fa = 'Asset (create)';
					|it = 'Oggetto di lavorazione (creazione)';
					|pl = 'Obiekty eksploatacji (tworzenie)';
					|tr = 'Valık (oluşturma)'"));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ClassWhenModifiedOnServer()
	
	UpdateAdditionalAttributesItems();
	UseOfSubclasses = False;
	UseOfSubclasses = RMManagementServerCall.UseOfSubclasses(Object.Class); 
	If UseOfSubclasses Then
		AttributeSet.Load(CompositionOfDetailsOfClassOfObjectOfOperation());
	Else
		AttributeSet.Load(Catalogs.Assets.CompositionOfDetailsOfObjectOfOperation());
	EndIf;
	
	Catalogs.Assets.WhenChangingClass(Object);

	FillInParametersForAccountingForDevelopments(RunningTimeRecordingParameters, Object.Class);
	ConfigureFormElementsByObjectClass();
	ConfigureDependentFormElements(ThisObject, "Class");
	
EndProcedure
 
#EndRegion

#Region StandardSubsystems

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

// Procedure for updating elements of additional object details in the form
//
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
