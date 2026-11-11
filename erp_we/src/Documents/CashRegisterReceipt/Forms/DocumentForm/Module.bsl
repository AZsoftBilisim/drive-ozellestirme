
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	If Object.Status <> Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_ Then
		Items.GroupDeliveryAmount.Visible = False;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CashRegisterReceipt));
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters); 
		SetVisibilityOfSeriesElements();
		FillInServiceDetailsForProductRange();
		Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
		
	EndIf;
	
	Items.GoodsPremise.Visible = WarehousesServer.UseWarerooms(Object.Warehouse,Object.Date);
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	SetAvailabilityOfDocumentCreationCommandsForReturns();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	OnCreateAtServerLocalization(Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	RecalculateDocumentOnClient();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CashRegisterReceipt));
	SetVisibilityOfSeriesElements();
	FillInServiceDetailsForProductRange();
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);

	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	FillInServiceDetailsForProductRange();

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_CashRegisterReceipt", WriteParameters, Object.Ref);

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FiscalOperationStatusURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	FiscalOperationNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If SetsClient.ItemToLock(Field) Then
		
		CurrentRow = Object.Goods.FindByID(RowSelected);
		If ValueIsFilled(CurrentRow.ProductsInSet) Then
			
			NotificationParameter1 = New Structure;
			NotificationParameter1.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
			NotificationParameter1.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
			NotificationParameter1.Insert("OwnerForm", UUID);
			
			Notify("EditSet", NotificationParameter1, ThisObject);
			
		EndIf;
		
	ElsIf Field = Items.GoodsProductsInSet Then
		ShowValue(Undefined, Items.Goods.CurrentData.ProductsInSet);
	ElsIf Field = Items.GoodsBatchesIndicationStatus
		Or Field = Items.GoodsSeries Then
		
		OpenSelectionOfSeries();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure SendNSPKConfirmation(Command)
	
	SendConfirmationToNSPCOnLocalizationClient();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False);

	//

	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False);
	
	//

	SetsServer.SetConditionalAppearance(ThisObject, "Goods");
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	FiscalOperationUpdateStatus();
	
EndProcedure

#Region Sets

&AtClient
// Called via the description of the message from the general module setclient 
Procedure WhenRemovingComponents(Action, AdditionalParameter) Export
	
	If SetsClient.EditSetAction(Action) Then
		SetsClient.WhenRemovingComponents(ThisObject, "Goods", AdditionalParameter);
	ElsIf SetsClient.DeleteEntireSetAction(Action) Then
		WhenRemovingComponentsOnServer("Goods", AdditionalParameter);
	EndIf;
	
	RecalculateDocumentOnClient();
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter)
	
	SetsServer.WhenRemovingComponents(ThisObject, TSName, AdditionalParameter);
	
EndProcedure

#EndRegion

#Region FiscalTransaction

&AtServer
Procedure FiscalOperationUpdateStatus()
	
	If ValueIsFilled(Object.Ref)
			And Object.Status = Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_ Then
		FiscalOperationLogData = PeripheralsReceiptPrinters.FiscalOperationData(Object.Ref);
		FiscalOperationUpdateStatusLocalization(FiscalOperationLogData);
	Else
		FiscalOperationLogData = Undefined;
	EndIf;
	
	Rows = New Array;
	If FiscalOperationLogData = Undefined Then
		
		Rows.Add("");
		
	Else
		
		Rows.Add(
			New FormattedString(
				StrTemplate(
					NStr("vi = 'Đã đánh phiếu số%1';
						|ru = 'Пробит чек №%1';
						|en = 'Receipt No.%1 is issued'; fa = 'Receipt No.%1 is issued';
						|it = 'Scontrino №%1 emesso';
						|pl = 'Wydrukowano paragon nr%1';
						|tr = 'Fiş No%1 kesildi'"),
					FiscalOperationLogData.CashRegisterReceiptNumber),,
				StyleColors.HyperlinkColor,,
				"OpenRecordOfFiscalTransaction"));
		
	EndIf;
	
	FiscalOperationStatus = New FormattedString(Rows);
	
EndProcedure

&AtClient
Procedure FiscalOperationNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If "OpenRecordOfFiscalTransaction" = FormattedStringURL Then
		
		TMPeripheralsClient.OpenRecordOfFiscalTransaction(ThisObject, Object.Ref);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure RecalculateDocumentOnClient()
	
	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Object.Goods, Object.PriceIncludesVAT);
	
	PaidOther = Object.PaymentWithPaymentCards.Total("Sum") + Object.GiftCertificates.Total("Sum");
	
	ChangeAmount = Object.PaymentWithPaymentCards.Total("Sum")
		+ Object.GiftCertificates.Total("Sum")
		+ Object.ReceivedInCash
		- Object.DocumentAmount;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfDocumentCreationCommandsForReturns()
	
	StructureRegisterShiftState = RetailSales.GetCashShiftState(Object.CashRegister);
	CashShiftIsOpen = StructureRegisterShiftState.ShiftIsOpened;
	ReceiptCompleted = (Object.Status =  Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormDocumentCheckCashRegisterRefundCreateBasedOn",                   "Enabled", ReceiptCompleted And CashShiftIsOpen);
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormDocumentReturnOfGoodsFromCustomerCreateBasedOn",         "Enabled", ReceiptCompleted);
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormDocumentRequestForReturnOfGoodsFromClientToCreateOnBasisOf", "Enabled", ReceiptCompleted);
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormDocumentCheckCashRegisterCorrectionCreateOnBasisOf",                 "Enabled", CashShiftIsOpen);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsBatchesIndicationStatus.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible               = SeriesSpecificationParameters.UseItemsBatch;
	
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

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert(
		"FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert(
		"FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.Goods, ParametersForFillingInBankingDetails);
	
	SetsServer.FillInServiceDetails(ThisObject);
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries()
	
	CurrentData = Items.Goods.CurrentData;
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject, SeriesSpecificationParameters, "", CurrentData) Then
		
		CurDataId = CurrentData.GetID();

		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
		OpenForm(
			ParametersOfSeriesIndicationForm.FormName,
			ParametersOfSeriesIndicationForm,ThisObject,,,,,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(
		Object, SeriesSpecificationParameters, CurDataId, ThisObject);
	
EndFunction

#EndRegion

#Region PrivateLocalization

&AtClient
Procedure SendConfirmationToNSPCOnLocalizationClient()
	
	
EndProcedure

&AtServer
Procedure FiscalOperationUpdateStatusLocalization(FiscalOperationLogData)
	
	
EndProcedure

&AtServer
Procedure OnCreateAtServerLocalization(Cancel, StandardProcessing)
	
	
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
