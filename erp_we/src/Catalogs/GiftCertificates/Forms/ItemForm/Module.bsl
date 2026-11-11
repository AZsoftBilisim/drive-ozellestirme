
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		Number = "";
		Date = "";
		OnCreatReadAtServer();
	EndIf;
	
	ObjectAttributesValues = TMCommonUse.StructureWithMetadataObjectProperties(Metadata.Catalogs.GiftCertificates);
	ObjectAttributesValues.Insert("Status");
	ObjectAttributesValues.Insert("GiftCardAccounting25");
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);
	NotifyAboutCreationOfCalculationObject = Parameters.NotifyAboutCreationOfCalculationObject;
	If NotifyAboutCreationOfCalculationObject Then 
		ViewSelectionParameters = New Array;
		ViewSelectionParameters.Add(New ChoiceParameter("Filter.GiftCardAccounting25", True));
		ViewSelectionParameters.Add(New ChoiceParameter("Filter.Organization", Object.Organization));
		Items.Owner.ChoiceParameters = New FixedArray(ViewSelectionParameters);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_GiftCertificates"
		Or EventName = "Write_GiftCertificateSale"
		Or EventName = "Write_ReturnOfGiftCards"
		Or EventName = "Write_CashAccountReceiptNote"
		Or EventName = "Write_BankAccountReceiptNote"
		Or EventName = "Write_CashVoucher"
		Or EventName = "Write_BankAccountIssue"
		Or EventName = "Write_PaymentCardTransaction"
		Or EventName = "Write_CashRegisterReceipt"
		Or EventName = "Write_ARAPSettlement" Then
			
		UpdateCurStateSetVisibilityOfItems();
		// StandardSubsystems.AttachableCommands
		AttachableCommandsClient.StartCommandUpdate(ThisObject);
		// End StandardSubsystems.AttachableCommands
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisObject);

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnCreatReadAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_GiftCertificates", , Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit 
		And ValueIsFilled(Object.Ref)
		And NotifyAboutCreationOfCalculationObject Then
		ARAPAccountingClient.FormWhenClosing(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OwnerOnChange(Item)
	
	OwnerWhenChangedOnServer();
	OnCreatReadAtServer();
	
EndProcedure

&AtServer
Procedure OwnerWhenChangedOnServer()
	
	AttributesValues = Common.ObjectAttributesValues(Object.Owner, "Organization,GiftCardAccounting25");
	Organization = AttributesValues.Organization;
	SetVisibilityOfOrganizationFormElement(AttributesValues.GiftCardAccounting25);
	
EndProcedure

&AtClient
Procedure MagneticCodeOnChange(Item)
	GenerateSelectionListForName(ThisObject);
EndProcedure

&AtClient
Procedure BarcodeOnChange(Item)
	GenerateSelectionListForName(ThisObject);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure OnCreatReadAtServer()
	
	UpdateCurStateSetVisibilityOfItems();		
	GenerateSelectionListForName(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure GenerateSelectionListForName(Form)
	
	Attributes = GeneralPurposeTMServerCall.ObjectAttributesValues(Form.Object.Owner, "Currency, Nominal");
	
	NameString_ = String(Form.Object.Owner)
	                     + ?(ValueIsFilled(Form.Object.Barcode), " " + String(Form.Object.Barcode), "")
	                     + ?(ValueIsFilled(Form.Object.MagneticCode), " " + String(Form.Object.MagneticCode), "");
	
	Form.Items.Description.ChoiceList.Clear();
	Form.Items.Description.ChoiceList.Add(NameString_);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfOrganizationFormElement(GiftCardAccounting25)
	
	If Not ValueIsFilled(Object.Owner) Then
		Return;
	EndIf;
		
	If GiftCardAccounting25 Then
		Items.Organization.Visible = True;
	Else
		Items.Organization.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateCurStateSetVisibilityOfItems()
	
	Data = GiftCertificatesServerCall.GetGiftCertificateDetails(Object.Ref, Object.Owner);
	
    ValidityStartDate 		= Data.ValidityStartDate;
    ValidityEndDate 	= Data.ValidityEndDate;
	Organization 			= Data.Organization;
	Balance 				= Data.Balance;
	GiftCardAccounting25 = Data.GiftCardAccounting25;
	Number 					= "";
	If ValueIsFilled(Data.DocumentSales) Then
		SetPrivilegedMode(True);
		ValuesOfAttributesOfSalesDocument = Common.ObjectAttributesValues(Data.DocumentSales, "Number,Date");
		SetPrivilegedMode(False);
		Number = ValuesOfAttributesOfSalesDocument.Number;
	EndIf;
	
	Status					= Data.StatusFromHistoryOfGiftCertificates;
	If ValueIsFilled(Object.Owner) And Data.GiftCardAccounting25 Then
		DataForCalculatingStatus = GiftCertificatesClientServer.DataForCalculatingStatus();
		FillPropertyValues(DataForCalculatingStatus, Data);
		Status = GiftCertificatesClientServer.CalculateStatusOfGiftCertificate2_5(DataForCalculatingStatus);
	EndIf;
	
	Items.Barcode.Visible     = (Data.CardType = Enums.CardTypes.Barcode_ Or Data.CardType = Enums.CardTypes.Mixed);
	Items.MagneticCode.Visible = (Data.CardType = Enums.CardTypes.Magnetic Or Data.CardType = Enums.CardTypes.Mixed);
	SetVisibilityOfOrganizationFormElement(Data.GiftCardAccounting25);
	
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
	
	ObjectAttributesValues.Insert("Status", Status);
	ObjectAttributesValues.Insert("GiftCardAccounting25", GiftCardAccounting25);
	FillPropertyValues(ObjectAttributesValues, Object);
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, ObjectAttributesValues);
EndProcedure

// End StandardSubsystems.AttachableCommands

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
