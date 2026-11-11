
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	SupportedPeripheralTypes = "BarcodeScanner,MagneticStripeCardReaders";
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	CurrentDate = CurrentSessionDate();
	
	If Not ValueIsFilled(Object.Ref) And ValueIsFilled(Object.Owner) Then
		
		Query = New Query(
		"SELECT
		|	LoyaltyCardKinds.Status,
		|	LoyaltyCardKinds.ValidityStartDate,
		|	LoyaltyCardKinds.ValidityEndDate,
		|	LoyaltyCardKinds.CardType
		|FROM
		|	Catalog.LoyaltyCardKinds AS LoyaltyCardKinds
		|WHERE
		|	LoyaltyCardKinds.Ref = &Ref");
		
		Query.SetParameter("Ref", Object.Owner);
		
		Result = Query.Execute();
		Selection = Result.Select();
		Selection.Next();
		
		If ValueIsFilled(Selection.ValidityEndDate) And BegOfDay(CurrentDate) > Selection.ValidityEndDate Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thời hạn hiệu lực của thẻ khách hàng thân thiết ""%1"" đã hết.';
																				|ru = 'Срок действия карт лояльности ""%1"" истек.';
																				|en = 'Loyalty cards ""%1"" have expired.'; fa = 'Loyalty cards ""%1"" have expired.';
																				|it = 'Le carte fedeltà ""%1"" sono scadute.';
																				|pl = 'Termin ważności kart lojalnościowych ""%1"" minął.';
																				|tr = '""%1"" sadakat kartlarının süresi doldu.'"), Object.Owner);
		EndIf;
		If Selection.Status = Enums.StatusesOfLoyaltyCardKinds.Closed Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thẻ khách hàng thân thiết ""%1"" đã đóng.';
																				|ru = 'Карты лояльности ""%1"" закрыты.';
																				|en = 'Loyalty cards ""%1"" are closed.'; fa = 'Loyalty cards ""%1"" are closed.';
																				|it = 'Le carte fedeltà ""%1"" sono chiuse.';
																				|pl = 'Karty lojalnościowe ""%1"" zostały zamknięte.';
																				|tr = 'Sadakat kartları ""%1"" kapalı.'"), Object.Owner);
		EndIf;
		
	EndIf;
	
	WhenChoosingTypeOfLoyaltyCard();
	GenerateAutoName(ThisForm);
	FillInPartnerInformation(); 
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

	FillInPartnerInformation();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, SupportedPeripheralTypes);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
		ElsIf EventName ="TracksData" Then
			ProcessMagneticCardReaderData(Parameter);
		EndIf;
	EndIf;
	// End Peripherals
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Properties
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	// End Properties

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisForm);

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_LoyaltyCards", , Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure PartnerOnChange(Item)
	
	FillInPartnerInformation();
	
EndProcedure

&AtClient
Procedure OwnerOnChange(Item)
	
	WhenChoosingTypeOfLoyaltyCard();
	GenerateAutoName(ThisForm);
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	
	AgreementSelectionParameters.Item               = Item;
	AgreementSelectionParameters.Partner               = Object.Partner;
	AgreementSelectionParameters.Document              = Object.Terms;
	AgreementSelectionParameters.DocumentDate         = CurrentDate;
	AgreementSelectionParameters.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomer");
	AgreementSelectionParameters.FormDataStructure  = Object;
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);
	
EndProcedure

&AtServer
Procedure WhenChoosingTypeOfLoyaltyCard()
	
	Query = New Query(
	"SELECT
	|	LoyaltyCardKinds.Status,
	|	LoyaltyCardKinds.ValidityStartDate,
	|	LoyaltyCardKinds.ValidityEndDate,
	|	LoyaltyCardKinds.Personalized,
	|	LoyaltyCardKinds.CardType
	|FROM
	|	Catalog.LoyaltyCardKinds AS LoyaltyCardKinds
	|WHERE
	|	LoyaltyCardKinds.Ref = &Ref");
	
	Query.SetParameter("Ref", Object.Owner);
	
	Result = Query.Execute();
	Selection = Result.Select();
	If Selection.Next() Then
	
		CardType = Selection.CardType;
		
		Items.Barcode.Visible = (CardType = Enums.CardTypes.Barcode_ Or CardType = Enums.CardTypes.Mixed);
		Items.MagneticCode.Visible = (CardType = Enums.CardTypes.Magnetic Or CardType = Enums.CardTypes.Mixed);
		Items.OwnerGroup.Visible = Selection.Personalized;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OwnerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterStructure1 = New Structure("ControlEndDate");
	FormParameters  = New Structure("Filter", FilterStructure1);
	
	OpenForm("Catalog.LoyaltyCardKinds.ChoiceForm",
	    FormParameters,
	    Item,,,,,
	    FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteDownThePartnerSDataAndCloseTheForm(Command)
	
	RecordPartnerDataOnServer();
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

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

#Region BarcodesAndTradeEquipment

// ExternalEquipmentMechanism
&AtClient
Procedure ProcessBarcodes(BarcodeData_1)
	
	Object.Barcode = BarcodeData_1[0].Barcode;
	
EndProcedure
// End ExternalEquipmentMechanism

&AtClient
Procedure ProcessMagneticCardReaderData(Data)
	
	ListOfCodes = New ValueList;
	
	DecryptedData = Data[1][3];
	If DecryptedData <> Undefined Then
		For Each Structure In DecryptedData Do
			
			MagneticStripeCardTemplate = Structure.Template;
			CardCode             = Undefined;
			For Each FieldData In Structure.TrackData Do
				If FieldData.Field = PredefinedValue("Enum.MagneticStripeCardTemplateFields.Code") Then
					ListOfCodes.Add(FieldData.Simple);
				EndIf;
			EndDo;
			
		EndDo;
	EndIf;
	
	If ListOfCodes.Count() = 1 Then
		Object.MagneticCode = ListOfCodes.Get(0).Value;
	ElsIf ListOfCodes.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Mã thẻ %1 không tương ứng với một trong các khuôn mẫu thẻ từ.';
										|ru = 'Код карты %1 не соответствует ни одному из шаблонов магнитных карт.';
										|en = 'The %1 card code does not correspond to any magnetic card templates.'; fa = 'The %1 card code does not correspond to any magnetic card templates.';
										|it = 'Il codice della carta %1 non corrisponde nemmeno ad uno dei modelli delle carte magnetiche.';
										|pl = 'Kod karty %1 nie odpowiada żadnemu szablonowi kart magnetycznych.';
										|tr = '%1kart kodu, manyetik kart numunelerinin hiçbiriyle eşleşmiyor.'"));
	Else
		ValueSelected = Undefined;

		ListOfCodes.ShowChooseItem(New CallbackDescription("ProcessMagneticCardReaderDataCompletion", ThisObject), NStr("vi = 'Chọn mã thẻ từ';
																														|ru = 'Выбор кода магнитной карты';
																														|en = 'Select magnetic stripe card code'; fa = 'Select magnetic stripe card code';
																														|it = 'Scelta del codice della carta magnetica';
																														|pl = 'Wybór kodu karty magnetycznej';
																														|tr = 'Manyetik şeritli kartın kodunu seçin'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessMagneticCardReaderDataCompletion(SelectedElement, AdditionalParameters) Export
    
    ValueSelected = SelectedElement;
    If ValueSelected <> Undefined Then
        Object.MagneticCode = ValueSelected.Value;
    EndIf;

EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

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
Procedure BarcodeOnChange(Item)
	GenerateAutoName(ThisForm);
EndProcedure

&AtClient
Procedure MagneticCodeOnChange(Item)
	GenerateAutoName(ThisForm);
EndProcedure

&AtClientAtServerNoContext
Procedure GenerateAutoName(Form)
	
	Description = String(Form.Object.Owner)
	               + ?(ValueIsFilled(Form.Object.Barcode), " " + String(Form.Object.Barcode), "")
	               + ?(ValueIsFilled(Form.Object.MagneticCode), " " + String(Form.Object.MagneticCode), "");
	
	Form.Items.Description.ChoiceList.Clear();
	Form.Items.Description.ChoiceList.Add(Description);
	
	If ValueIsFilled(Form.Object.Description) And Description <> Form.Object.Description Then
		Form.Items.Description.ChoiceList.Add(Form.Object.Description);
	EndIf;
	
EndProcedure

&AtServer
Procedure RecordPartnerDataOnServer()
	
	SetPrivilegedMode(True);
	
	PartnerObject_ = Object.Partner.GetObject();
	PartnerObject_.DescriptionFull              = Fiopartner;
	PartnerObject_.Gender                             = PartnerSGender;
	PartnerObject_.BirthDate                    = PartnerSDateOfBirth;
	PartnerObject_.OptionOfSendingElectronicReceipt = OptionOfSendingElectronicReceipt;
	PartnerObject_.Write();
	
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Procedure FillInPartnerInformation()
	
	LoyaltyCardDetails = LoyaltyCardServerCall.GetLoyaltyCardDetails(Object.Ref, True);
	
	Items.Partner.Visible    = LoyaltyCardDetails.PartnerAvailable;
	Items.Counterparty.Visible =  LoyaltyCardDetails.CounterpartyAvailable;
	Items.Terms.Visible =  LoyaltyCardDetails.AgreementAvailable;
	
	SetPrivilegedMode(True);
	AttributesValues = Common.ObjectAttributesValues(Object.Partner,"BirthDate,Gender,LegalEntityIndividual,DescriptionFull,OptionOfSendingElectronicReceipt");
	SetPrivilegedMode(False);
	
	PartnerSGender                     = AttributesValues.Gender;
	PartnerSDateOfBirth            = AttributesValues.BirthDate;
	Fiopartner                     = AttributesValues.DescriptionFull;
	OptionOfSendingElectronicReceipt = AttributesValues.OptionOfSendingElectronicReceipt;
	
	ShowPartnerData =
		ValueIsFilled(Object.Partner)
		And (AttributesValues.LegalEntityIndividual = Enums.IndividualCompany.Person_);
		
	Items.GroupDataOfAnIndividualSPartner.Visible = ShowPartnerData;
	If ShowPartnerData Then
		
		CWPAccessRights = SalesSettingsForUsersServer.CWPAccessRights(Users.CurrentUser());
		Items.GroupDataOfAnIndividualSPartner.Enabled = CWPAccessRights.EditingCustomerInformation
			And Not LoyaltyCardDetails.PartnerAvailable;
		
		If CWPAccessRights.EditingCustomerInformation
			And Not LoyaltyCardDetails.PartnerAvailable Then
			
			Items.WriteDownThePartnerSDataAndCloseTheForm.Visible = True;
			Items.WriteDownThePartnerSDataAndCloseTheForm.DefaultButton = True;
			Items.WriteAndClose.Visible = False;
			
		EndIf;
		
	EndIf;
	
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
