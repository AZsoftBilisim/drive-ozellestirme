#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	TMCommonUse.CustomizePeripherals(ThisForm);
	
	UseDiscountAdjustmentsInSales = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	TimeList = TMCommonUseClientServer.TimeList();
	
	For Each ListItem In TimeList Do
		Items.BeginTime.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
		Items.EndTime.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
	EndDo;
	
	SetVisibilityAndAccessibilityOfElements();
	
	If Not Object.ItemsDetails Then
		Items.GoodsNumberOfPackages.Title = NStr("vi = 'Số lượng';
												|ru = 'Количество';
												|en = 'Quantity'; fa = 'مقدار';
												|it = 'Quantità';
												|pl = 'Quantity';
												|tr = 'Miktar'");
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	SetAvailabilityOfClipboardCommands();
	
	SalesServer.SetBlankContractMark(Items, "Contract", ToUseTheTransferOfGoodsToStorage);
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	FillInSalesVATTaxation();
	
	Items.GoodsPriceKind.QuickChoice = Not GetFunctionalOption("UseSeveralPriceTypes");

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	// StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
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
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("WriteParameters", WriteParameters);
	
	Cancel = True;
	ReusablePackageClient.OfferToPickUpMultiTurnContainer(
		ThisForm,
		"Goods",
		"Products,Characteristic,Count",
		New CallbackDescription("BeforeRecordingOfferToPickUpMultiTurnContainer", ThisObject, AdditionalParameters));
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToPickUpMultiTurnContainer(Result, AdditionalParameters) Export
	
	If PossibleCollisionsWithMobileApplication(Object.Ref) Then
		
		QueryText = NStr("vi = 'Bản ghi của nhiệm vụ mà đã chuẩn bị hoặc xử lý từ trước, %Linefeed%có thể dẫn đến xung đột khi trao đổi với ứng dụng di động.%Linefeed%Tiếp tục?';
						|ru = 'Запись задания, которое было ранее подготовлено или отработано,%Linefeed%может привести к коллизиям при обмене с мобильным приложением.%Linefeed%Продолжить?';
						|en = 'Saving a job that was previously prepared or processed%Linefeed%can cause collisions when exchanging data with mobile application.%Linefeed%Continue?'; fa = 'Saving a job that was previously prepared or processed%Linefeed%can cause collisions when exchanging data with mobile application.%Linefeed%Continue?';
						|it = 'La registrazione di task precedentemente preparato o elaborato,%Linefeed%può causare collisioni durante lo scambio con un''applicazione mobile.%Linefeed%Continuare?';
						|pl = 'Zapis zadania, które zostało wcześniej przygotowano lub przetwórzono,%Linefeed%może doprowadzić do кolizji przy wymianie z aplikacją mobilną.%Linefeed%Kontynuować?';
						|tr = 'Önceden hazırlanmış veya üzerinde çalışılmış bir işi kaydetmek,%Linefeed% mobil uygulama ile alışveriş yaparken çakışmalara yol açabilir.%Linefeed% Devam edilsin mi?'");
		QueryText = StrReplace(QueryText,"%Linefeed%",Chars.LF);
		ShowQueryBox(
			New CallbackDescription("BeforeWritingQuestionAboutCollisionsEnds", ThisObject, AdditionalParameters),
			QueryText,
			QuestionDialogMode.YesNo,
			,
			DialogReturnCode.No);
		
	Else
		
		If Not Object.NotShipInInstallments Then
			
			Cancel = False;
			
			PaymentStepsClient.AskQuestionAboutResettingScheduleONChangesInShippingDate(
				ThisObject,
				New CallbackDescription(
					"BeforeRecordingAskQuestionAboutResettingScheduleONChangesInShipmentDateEnd", 
					ThisObject, 
					AdditionalParameters),
				Cancel);
			
			If Cancel Then
				Return;
			EndIf;
			
		EndIf;
		
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
		
	EndIf;
		
EndProcedure

&AtClient
Procedure BeforeWritingQuestionAboutCollisionsEnds(QuestionResult, AdditionalParameters) Export
	
	TheUserResponse = QuestionResult;
	If TheUserResponse = DialogReturnCode.Yes Then
		
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeRecordingAskQuestionAboutResettingScheduleONChangesInShipmentDateEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Object.PaymentScheduleSteps.Clear();
	EndIf;
	ARAPAccountingClient.QuestionAboutResettingScheduleONChangesInShippingDatesHasBeenAsked(ThisObject);
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	Items.GroupComment.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	UseVariants = New Structure("Products", "ItemVariantsAreUsed");
	ItemsTypes = New Structure("Products", "ItemsType");
	SalesRegistrationOptions = New Structure("Products", "SaleRegistrationOption");
	Articles = New Structure("Products", "SKU");
			
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", UseVariants);
	StructureOfActions.Insert("FillInProductTypeAttribute_", ItemsTypes);
	StructureOfActions.Insert("FillInSalesOptionAttribute", SalesRegistrationOptions);
	StructureOfActions.Insert("FillInArticleAttribute", Articles);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	
	UpdateNoReturnableContainerAttribute();
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_JobForSalesRepresentative",Object.Partner,Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		HandlingSelectionSelectionOnClient(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.SelectReusablePackage.Form.Form" Then
		
		FillMultiTurnContainersFromStorageServer(ValueSelected.AddressOfReusableContainerInStorage);
		ReusablePackageClient.NotifyUserAboutFillingMultiTurnContainers();
		
	Else
		If TypeOf(ValueSelected) = Type("DocumentRef.JobForSalesRepresentative")
			Or TypeOf(ValueSelected) = Type("DocumentRef.SalesOrder") Then
			
			If ValueIsFilled(ValueSelected) Then
				
				If Object.Goods.Count()>0 Then
					QueryText = NStr("vi = 'Thành phần nhiệm vụ đã điền trước sẽ bị xóa. Tiếp tục?';
									|ru = 'Ранее заполненный состав задания будет очищен. Продолжить?';
									|en = 'Job content filled in earlier will be cleared. Continue?'; fa = 'Job content filled in earlier will be cleared. Continue?';
									|it = 'La composizione del task precedentemente compilata verrà cancellata. Continuare?';
									|pl = 'Wcześniej wypełniony skład zadania będzie oczyszczony. Kontynuować?';
									|tr = 'Önceden tamamlanmış iş kompozisyonu silinecektir. Devam edilsin mi?'");
					Structure = New Structure("ValueSelected", ValueSelected);
					CallbackDescription = New CallbackDescription("ChoiceProcessingCompletion", ThisObject, Structure);
					ShowQueryBox(CallbackDescription, QueryText,QuestionDialogMode.YesNo);
				Else
					ProcessFillingBasedOn(ValueSelected);
				EndIf;
				
			EndIf;
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure ChoiceProcessingCompletion(QuestionResult, AdditionalParameters) Export
    
    TheUserResponse = QuestionResult;
    
    If TheUserResponse = DialogReturnCode.No Then
        Return;
	EndIf;
	
	ValueSelected = AdditionalParameters.ValueSelected;
    ProcessFillingBasedOn(ValueSelected);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
			
		EndIf;
		
	EndIf;
	// End Peripherals

	// Unknown barcodes
	If EventName = "UnknownBarcodes"
		And Source = "Peripherals"
		And Parameter.OwnerForm = UUID Then
		
		CachedValues.Barcodes.Clear();
		
		BarcodeData_5 = New Array;
		
		For Each ReceivedBarcode In Parameter.ItemsBarcodes Do
			BarcodeData_5.Add(ReceivedBarcode);
		EndDo;
		
		ProcessBarcodes(BarcodeData_5);
		
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "OrderConditions"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)

	AgreementSelectionParameters = SalesClient.ParametersForStartingSelectionOfAgreementWithClient();
	
	AgreementSelectionParameters.Item                     = Item;
	AgreementSelectionParameters.Partner                     = Object.Partner;
	AgreementSelectionParameters.Document                    = Object.Terms;
	AgreementSelectionParameters.DocumentDate               = Object.Date;
	AgreementSelectionParameters.OnlyUsedBySalesRepresentative = True;
	AgreementSelectionParameters.FormDataStructure        = Object;
	AgreementSelectionParameters.Insert("ServedBySalesRepresentatives", True);  
	
	SalesClient.StartSelectingAgreementWithClient(AgreementSelectionParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled(Object.Partner) Then
		Return;
	EndIf;
	
	WhenChangingPartnerServer();
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)

	If Not ValueIsFilled (Object.Terms) Then
		Return;
	EndIf;
	
	WhenChangingAgreementAtServer();

EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	RecalculationOfTablePartsIsRequired = ConversionToPMCurrencyIsRequired(Object.Currency);
	RecalculationOfPlannedAmountIsRequired = ItIsRequiredToRecalculatePlannedAmount(Object.Currency);
	
	OldCurrency = DocumentCurrency;
	DocumentCurrency = Object.Currency;
	
	RecalculateAmounts = (RecalculationOfTablePartsIsRequired Or RecalculationOfPlannedAmountIsRequired);
	
	CurrencyOnChangeServer(
		OldCurrency,
		RecalculateAmounts And RecalculationOfTablePartsIsRequired,
		RecalculateAmounts And RecalculationOfPlannedAmountIsRequired);
	
	If RecalculateAmounts Then
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	VATTaxationOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure ServiceTermsOnChange(Item)
	
	If Not ValueIsFilled(Object.ServiceTerms) Then
		Return;
	EndIf;
	
	ServiceTermsOnChangeServer();
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationOnChangeServer();
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	Items.GoodsOpenSelection.Enabled = (Object.Status = PredefinedValue("Enum.SalesRepresentativeTaskStatuses.NotPrepared2"));
	
EndProcedure

&AtClient
Procedure StatusClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure ToReturnReusablePackageOnChange(Item)
	
	ToReturnReusablePackageOnChangeServer();
	
EndProcedure

&AtClient
Procedure PackageDepositIsRequiredOnChange(Item)
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTasks

&AtClient
Procedure TasksTaskDetails1StartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText,
		ThisObject,
		"Items.Tasks.CurrentData.TaskDetails1",
		NStr("vi = 'Mô tả nhiệm vụ';
			|ru = 'Описание задачи';
			|en = 'Task description'; fa = 'شرح وظیفه';
			|it = 'Descrizione dell''obiettivo';
			|pl = 'Opis zadań';
			|tr = 'Görev açıklaması'"));
	
EndProcedure

&AtClient
Procedure TasksResultDetailsStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText,
		ThisObject,
		"Items.Tasks.CurrentData.ResultDetails",
		NStr("vi = 'Mô tả kết quả';
			|ru = 'Описание результата';
			|en = 'Result description'; fa = 'شرح نتیجه';
			|it = 'Descrizione del risultato';
			|pl = 'Opis rezultatu';
			|tr = 'Sonuç açıklaması'"));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.GoodsPrice Then
		
		CurrentData = Items.Goods.CurrentData;
		If ValueIsFilled(CurrentData.PriceKind) Then
			ClearMessages();
			CommonClientServer.MessageToUser(
				NStr("vi = 'Để soạn đơn giá, hãy xóa dạng giá';
					|ru = 'Для редактирования цены очистите вид цены';
					|en = 'To edit the price, clear the price type'; fa = 'To edit the price, clear the price type';
					|it = 'Для редактирования цены очистите вид цены';
					|pl = 'To edit the price, clear the price type';
					|tr = 'Fiyatı düzenlemek için fiyat türünü temizleyin'"),
				Object.Ref,
				CommonClientServer.PathToTabularSection("Object.Goods", CurrentData.LineNumber, "PriceKind"),);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	CurrentRow = Items.Goods.CurrentData;
	
	SalesClient.ProductItemLineAtBeginningOfEditing(ThisForm, "Goods", CurrentRow, NewRow, Copy);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	ReusablePackageClient.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateNumberOfSuffixUnits","Plan");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());   
	
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInSalesOptionAttribute", New Structure("Products", "SaleRegistrationOption"));
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, True));
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateNumberOfSuffixUnits","Plan");
	If CurrentRow.Count > 0 And Not ValueIsFilled(CurrentRow.PriceKind) Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	ElsIf CurrentRow.Count > 0 And ValueIsFilled(CurrentRow.PriceKind) Then
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	ElsIf (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActions.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	EndIf;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesPlanOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfSuffixUnits","Plan");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPriceKindOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsPercentRateOfManualDiscountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsManualDiscountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePercentageOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, RecalculateAmountOfManualDiscount_", False, False));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	
	ParametersStructure = New Structure("UseManualDiscounts");
	StructureOfActions.Insert("RecalculatePriceDiscountByAmountInSales", ParametersStructure);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsVATAmountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsCancellationReasonOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	CurrentRow.Canceled = ValueIsFilled(CurrentRow.CancellationReason);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	WhenCancellationReasonChangesServer();
	
EndProcedure

&AtClient
Procedure GoodsCommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText,
		ThisObject,
		"Items.Goods.CurrentData.Comment");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

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
Procedure FillInTheTaskBasedOnTheSalesHistoryData(Command)
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("ItemsDetails", Object.ItemsDetails);
	ParametersStructure.Insert("Partner", Object.Partner);
	ParametersStructure.Insert("Counterparty", Object.Counterparty);
	
	Notification = New CallbackDescription("FillInTheTaskBasedOnTheSalesHistoryDataCompletion", ThisObject);
	
	OpenForm("Document.JobForSalesRepresentative.Form.FillingBySalesHistoryData",
					ParametersStructure, ThisObject,,,, Notification);
	
EndProcedure

&AtClient
Procedure FillInTheTaskBasedOnTheSalesHistoryDataCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	If Object.Goods.Count()>0 Then
		
		QueryText = NStr("vi = 'Thành phần nhiệm vụ đã điền trước sẽ bị xóa. Tiếp tục?';
						|ru = 'Ранее заполненный состав задания будет очищен. Продолжить?';
						|en = 'Job content filled in earlier will be cleared. Continue?'; fa = 'Job content filled in earlier will be cleared. Continue?';
						|it = 'La composizione del task precedentemente compilata verrà cancellata. Continuare?';
						|pl = 'Wcześniej wypełniony skład zadania będzie oczyszczony. Kontynuować?';
						|tr = 'Önceden tamamlanmış iş kompozisyonu silinecektir. Devam edilsin mi?'");
		
		Structure = New Structure("FillParameters", Result);
		
		CallbackDescription = New CallbackDescription("FillInTaskBasedOnSalesHistoryCompletionOfQuestion", ThisObject, Structure);
		ShowQueryBox(CallbackDescription, QueryText,QuestionDialogMode.YesNo);
    Else
		FillOutTaskBasedOnSalesHistoryDataFragment(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTaskBasedOnSalesHistoryCompletionOfQuestion(QuestionResult, AdditionalParameters) Export
    
    Structure = AdditionalParameters.FillParameters;
    
    TheUserResponse = QuestionResult;
    
    If TheUserResponse = DialogReturnCode.No Then
        Return;
    EndIf;
    
    FillOutTaskBasedOnSalesHistoryDataFragment(Structure);

EndProcedure

&AtClient
Procedure FillOutTaskBasedOnSalesHistoryDataFragment(FillParameters)
    
    Var CharacteristicsDetails, EndOfPeriod, BeginOfPeriod, Period;
    
    Object.Goods.Clear();
    
    BeginOfPeriod = FillParameters.BeginOfPeriod;
    EndOfPeriod = FillParameters.EndOfPeriod;
    Period = GetPeriodForLayout(FillParameters.Period);
    CharacteristicsDetails = FillParameters.CharacteristicsDetails;
    
    FillInTaskBasedOnSalesHistoryDataServer(BeginOfPeriod, EndOfPeriod, Period, CharacteristicsDetails, FillParameters.Settings);
    
    CalculateTaskTotalsForSalesRepresentative(ThisForm);

EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.Title = NStr("vi = 'Hãy nhập số lượng (dự tính) trong dòng mới.';
											|ru = 'Введите количество (план) в новой строке.';
											|en = 'Enter quantity (plan) in a new line.'; fa = 'Enter quantity (plan) in a new line.';
											|it = 'Inserire la quantità (piano) nella nuova riga.';
											|pl = 'Wprowadź ilość (plan) w nowym wierszu.';
											|tr = 'Yeni satıra miktarı (plan) girin.'");
	StringSplittingParameters.FieldNameQuantity = "NumberOfPackagesPlan";
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData,FormTable, Notification, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		NewRow.NumberOfPackages = 0;
		NewRow.Count         = 0;
		
		StructureOfActions = New Structure;     		    
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);  		
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		CalculateTaskTotalsForSalesRepresentative(ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculateJobAmountAccordingToSalesHistoryDataExecute(Command)
	
	If Not ValueIsFilled(Object.Currency) Then
		MessageText = NStr("vi = 'Chưa chỉ ra tiền tệ chứng từ';
							|ru = 'Не указана валюта документа';
							|en = 'Specify document currency'; fa = 'Specify document currency';
							|it = 'Valuta del documento non specificata';
							|pl = 'Nie wskazano waluty dokumentu';
							|tr = 'Belgenin para birimi belirtilmedi'");
		CommonClientServer.MessageToUser(MessageText, Object, "Currency");
		Return;
	EndIf;
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("ItemsDetails", Object.ItemsDetails);
	ParametersStructure.Insert("Partner", Object.Partner);
	ParametersStructure.Insert("Counterparty", Object.Counterparty);
	
	Notification = New CallbackDescription("CalculateJobAmountAccordingToSalesHistoryDataCompletion", ThisObject);
	
	OpenForm("Document.JobForSalesRepresentative.Form.FillingBySalesHistoryData",
					ParametersStructure, ThisObject,,,, Notification);
	
EndProcedure

&AtClient
Procedure CalculateJobAmountAccordingToSalesHistoryDataCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	FillParameters = Result;
	
	BeginOfPeriod = FillParameters.BeginOfPeriod;
    EndOfPeriod = FillParameters.EndOfPeriod;
    Period = GetPeriodForLayout(FillParameters.Period);
	
	SetTaskAmountBasedOnSalesHistory(BeginOfPeriod, EndOfPeriod, Period, FillParameters.Settings);
	
EndProcedure

&AtClient
Procedure FillInTheJobWithThePreviousOneExecute(Command)
	
	OpenBaseSelectionForm("JobForSalesRepresentative");
	
EndProcedure

&AtClient
Procedure FillInTheTaskOnTheOrderExecute(Command)
	
	OpenBaseSelectionForm("SalesOrder");
	
EndProcedure

&AtClient
Procedure FillThePricesByTermsOfSales(Command)

	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Wiersze pozycji';
																									|tr = 'Ürünler'")) Then
		
		ErrorText = "";
		PricesCalculated = FillThePricesByTermsOfSalesServer(ErrorText);
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		
	EndIf;

EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceType(Command)

	If EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, "Goods", NStr("vi = 'Hàng hóa';
																									|ru = 'Товары';
																									|en = 'Goods'; fa = 'کالاها';
																									|it = 'Merci';
																									|pl = 'Wiersze pozycji';
																									|tr = 'Ürünler'")) Then
		
		PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
		PriceSelectionOptions.CallbackDescription = 
			New CallbackDescription("FillInPricesOfSelectedRowsByPriceTypeCompletion", ThisObject);
		PriceSelectionOptions.PriceIncludesVAT = Object.PriceIncludesVAT;
		PriceSelectionOptions.UseWhileSellingToCustomers = True;
		PriceSelectionOptions.OwnerOfAnIndividualPriceType = ?(ToUseTermsOfSales,Object.Terms,Object.Partner);
		
		EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
	EndIf;

EndProcedure

&AtClient
Procedure FillInPricesOfSelectedRowsByPriceTypeCompletion(PricesKind, AdditionalParameters) Export
	
	If ValueIsFilled(PricesKind) Then
		
		PricesCalculated = FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind);
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PricesKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AssignAManualDiscount(Command)
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToAssignManualDiscountMarkUp(Object, "Goods", NStr("vi = 'Hàng hóa';
																										|ru = 'Товары';
																										|en = 'Goods'; fa = 'کالاها';
																										|it = 'Merci';
																										|pl = 'Wiersze pozycji';
																										|tr = 'Ürünler'")) Then
		Return;
	EndIf;
	
	AddressInTempStorage = AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(False);
	
	Notification = New CallbackDescription(
		"AssignAManualDiscountCompletion", 
		ThisObject, 
		New Structure("AddressInTempStorage", AddressInTempStorage));
	
	DiscountsMarkupsFillingClient.OpenFormForAssigningManualDiscounts(
		AddressInTempStorage,
		Object.Currency,
		Notification);
	
EndProcedure

&AtClient
Procedure AssignAManualDiscountCompletion(AmountOfManualDiscountMarkUp, AdditionalParameters) Export 
	
	AddressInTempStorage = AdditionalParameters.AddressInTempStorage;
	
	If AmountOfManualDiscountMarkUp <> Undefined Then
		
		AssignManualDiscountOnServer(AmountOfManualDiscountMarkUp, AddressInTempStorage);
		
		CalculateTaskTotalsForSalesRepresentative(ThisForm);
		
		DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins(AmountOfManualDiscountMarkUp, Object.Currency);
		
	EndIf;

EndProcedure

&AtClient
Procedure CancelManualDiscounts(Command)
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToCancelManualDiscountsMarkups(Object, "Goods", NStr("vi = 'Hàng hóa';
																											|ru = 'Товары';
																											|en = 'Goods'; fa = 'کالاها';
																											|it = 'Merci';
																											|pl = 'Wiersze pozycji';
																											|tr = 'Ürünler'")) Then
		Return;
	EndIf;
	
	CancelManualDiscountsOnServer();
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
	DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins();
	
EndProcedure

&AtClient
Procedure OpenSelection(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.JobForSalesRepresentative.DocumentForm.Command.OpenSelection");
	
	Cancel = False;
	If (ToUseTermsOfSales And Not ValueIsFilled(Object.Terms))
		Or Not ToUseTermsOfSales
		Or Not ValueIsFilled(Object.Currency) Then
		ClearMessages();
		ReportErrorsWhenOpeningSelection(Cancel);
	EndIf;
	If Cancel Then
		Return;
	EndIf;
	
	HeaderParameter_ = NStr("vi = 'Chọn hàng hóa vào %Document%';
							|ru = 'Подбор товаров в %Document%';
							|en = 'Pick goods in %Document%'; fa = 'Pick goods in %Document%';
							|it = 'Selezione merci in %Document%';
							|pl = 'Wybór towarów w %Document%';
							|tr = '%Document% içindeki ürünlerin seçimi'");
	If ValueIsFilled(Object.Ref) Then
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", Object.Ref);
	Else
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'nhiệm vụ dành cho đại diện thương mại';
																			|ru = 'задание торговому представителю';
																			|en = 'sales representative task'; fa = 'sales representative task';
																			|it = 'task al rappresentante commerciale';
																			|pl = 'zadanie dla przedstawiciela handlowego';
																			|tr = 'satış temsilcisine görevler'"));
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Partner",            Object.Partner);
	FormParameters.Insert("Terms",         Object.Terms);
	FormParameters.Insert("Organization",        Object.Organization);
	FormParameters.Insert("PriceIncludesVAT",    Object.PriceIncludesVAT);
	FormParameters.Insert("ReturnReusablePackage", Object.ToReturnReusablePackage);
	FormParameters.Insert("VATTaxation", Object.VATTaxation);
	FormParameters.Insert("Warehouse",           Object.Warehouse);
	FormParameters.Insert("Currency",          Object.Currency);
	FormParameters.Insert("Title",       HeaderParameter_);
	FormParameters.Insert("Date",            Object.Date);
	FormParameters.Insert("Document",        Object.Ref);
	FormParameters.Insert("AllWarehouseBalance", True);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, Var_Parameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count()-NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure AddReusablePackage(Command)

	ReusablePackageClient.SelectReusablePackage(
		ThisForm,
		"Goods",
		"Products,Characteristic,Count");
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	TMCommonUseClient.WriteAndClose(ThisForm, True);
	
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

&AtClient
Procedure FillInVATRate(Command)

	If Object.Goods.Count() = 0 Then
		WarningText = NStr("vi = 'Trong danh sách ""Hàng hóa"" chưa điền dòng nào.';
							|ru = 'В список ""Товары"" не введено ни одной строки.';
							|en = 'No lines entered in the Item list.'; fa = 'No lines entered in the Item list.';
							|it = 'В список ""Товары"" не введено ни одной строки.';
							|pl = 'Do listy ""Wiersze pozycji"" nie wprowadzono żadnego wiersza.';
							|tr = '""Ürünler"" listesine hiçbir satır girilmemiştir.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;

	ClosingNotification1 = New CallbackDescription("FillInVATRateCompletion", ThisObject);
	FormParameters = New Structure();
	FormParameters.Insert("VATTaxationType", Object.VATTaxation);
	FormParameters.Insert("UpdateDate", Object.Date);
	OpenForm("Catalog.VATRates.ChoiceForm", FormParameters,,,,, ClosingNotification1);

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseDiscountAdjustmentsInSales");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(ThisForm);

	//

	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisForm);

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PlannedVisitDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.SalesRepresentativeTaskStatuses.Canceled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PlannedVisitDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ActualVisitDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SalesRepresentativeTaskStatuses.Processed_;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ActualVisitDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Partner.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.SalesRepresentativeTaskStatuses.Canceled);
	ValueList.Add(Enums.SalesRepresentativeTaskStatuses.NotPrepared2);
	ItemFilter.RightValue = ValueList;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Currency.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.SalesRepresentativeTaskStatuses.Canceled);
	ValueList.Add(Enums.SalesRepresentativeTaskStatuses.NotPrepared2);
	ItemFilter.RightValue = ValueList;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Currency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SalesRepresentative.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.SalesRepresentativeTaskStatuses.Canceled);
	ValueList.Add(Enums.SalesRepresentativeTaskStatuses.NotPrepared2);
	ItemFilter.RightValue = ValueList;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SalesRepresentative");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Supervisor_.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.SalesRepresentativeTaskStatuses.Canceled);
	ValueList.Add(Enums.SalesRepresentativeTaskStatuses.NotPrepared2);
	ItemFilter.RightValue = ValueList;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Supervisor_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BusinessOperation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.SalesRepresentativeTaskStatuses.Canceled);
	ValueList.Add(Enums.SalesRepresentativeTaskStatuses.NotPrepared2);
	ItemFilter.RightValue = ValueList;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.VATTaxation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.SalesRepresentativeTaskStatuses.Canceled);
	ValueList.Add(Enums.SalesRepresentativeTaskStatuses.NotPrepared2);
	ItemFilter.RightValue = ValueList;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.VATTaxation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	EnterprisePricesFillingServer.EstablishConditionalAppearanceOfPriceTypes(ThisForm);

	//
	
	ProductsServer.EstablishConditionalAppearanceOfContent(ThisForm);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Goods.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.CancellationReason");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATRate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ToReturnReusablePackage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

// StandardSubsystems.Properties
&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure
// End StandardSubsystems.Properties

#Region OnChangeAttributes

&AtServer
Procedure WhenChangingPartnerServer()
	
	FillIn_TermsOfSales();
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementAtServer(FillIn_TermsOfSales = True)
	
	If FillIn_TermsOfSales Then
		PaymentSchedule = Object.PaymentSchedule;
		
		DocumentSales = FormAttributeToValue("Object");
		DocumentSales.FillInTermsOfSalesUnderAgreement();
		ValueToFormData(DocumentSales,Object);
	EndIf;
	
	DocumentCurrency = Object.Currency;
	BusinessOperationOnChangeServer();
	
	AttributesArray = New Array;
	AttributesArray.Add("Contract");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	UpdateNoReturnableContainerAttribute();
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	
EndProcedure

&AtServer
Procedure ServiceTermsOnChangeServer()
	
	Terms   = Object.Terms;
	PaymentSchedule = Object.PaymentSchedule;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInTermsOfSalesUnderTermsOfService();
	ValueToFormData(DocumentSales,Object);
	
	If ToUseTermsOfSales 
		And Terms <> Object.Terms And ValueIsFilled(Object.Terms) Then
		WhenChangingAgreementAtServer(False);
	EndIf;
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If ValueIsFilled(Object.Organization) Then
		FillInDefaultContract();
		FillInSalesVATTaxation();
		VATTaxationOnChangeServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
	EndIf;
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ContractOnChangeServer();
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	FillInDefaultContract();
	
	TransferOperations_ = SalesServer.GoodsTransferOperations();
	
	If TransferOperations_.Find(Object.BusinessOperation) = Undefined Then
		FillInSalesVATTaxation();
		VATTaxationOnChangeServer();
	Else
		Object.PackageDepositIsRequired = False;
	EndIf;
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	SetAvailabilityOfItemsByOperationServer();
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer(OldCurrency, RecalculationOfTablePartsIsRequired, RecalculationOfPlannedAmountIsRequired)
	
	FillInDefaultContract();
	HandlingCurrencySelection(Object.Currency, OldCurrency, RecalculationOfTablePartsIsRequired, RecalculationOfPlannedAmountIsRequired);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
	If Not ToUseTermsOfSales Then
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
		PriceTypeSelectionParameters.PriceIncludesVAT        = Object.PriceIncludesVAT;
		PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;

		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer(CachedValues = Undefined)
	
	CachedValuesInternal = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate",
			BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object, False, Object.ToReturnReusablePackage));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValuesInternal);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValuesInternal.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

EndProcedure

&AtServer
Procedure WhenCancellationReasonChangesServer()
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
EndProcedure

#EndRegion

#Region PricingAndDiscounts

&AtClient
Function ConversionToPMCurrencyIsRequired(Currency)

	If Not ValueIsFilled(Currency) Then
		Return False;
	ElsIf DocumentCurrency = Currency Then
		Return False;
	ElsIf Object.Goods.Total("Price") = 0
		And Object.PaymentScheduleSteps.Total("PaymentAmount") = 0
		And Object.PaymentScheduleSteps.Total("PackageDepositValue") Then
		Return False;
	EndIf;
	
	Return True;

EndFunction

&AtServer
Procedure AssignManualDiscountOnServer(AmountOfDiscountMarkUp, AddressInTempStorage)
	
	DiscountParameters = DiscountsMarkupsFillingServer.NewOptionsAssignManualDiscount();
	DiscountParameters.AutomaticDiscountsAreUsed = False;
	DiscountParameters.CalculateAmountWithVAT			 = True;
	DiscountParameters.AddressInTempStorage		 = AddressInTempStorage;
	
	DiscountsMarkupsFillingServer.AssignAManualDiscount(Object, "Goods", AmountOfDiscountMarkUp, DiscountParameters);

	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
EndProcedure

&AtServer
Procedure CancelManualDiscountsOnServer()
	
	DiscountsMarkupsFillingServer.CancelManualDiscounts(Object, "Goods", False, True);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
EndProcedure

&AtServer
Function FillThePricesByTermsOfSalesServer(ErrorText = "")
	
	If Common.ObjectAttributeValue(Object.Terms, "PriceIncludesVAT") <> Object.PriceIncludesVAT Then
		ErrorText = 
		NStr("vi = 'Các giá trị đã đặt cho trường ""Đơn giá gồm thuế GTGT"" trong chứng từ và thỏa thuận là khác nhau.';
			|ru = 'Установленные значения полей ""Цена включает НДС"" в документе и соглашении разные.';
			|en = 'Set values of the ""Price includes VAT"" fields in the document and agreement are different.'; fa = 'Set values of the ""Price includes VAT"" fields in the document and agreement are different.';
			|it = 'I valori impostati dei campi ""Prezzo IVA inclusa"" nel documento e nell''accordo differiscono.';
			|pl = 'Ustawione wartości pól ""Cena brutto"" w dokumencie i umową są różne.';
			|tr = 'Belgedeki ve sözleşmedeki ""KDV dahildir"" alanlarının hesaplanan değerleri farklıdır.'");
		Return False;
	EndIf;

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	// The fill parameters
	FillingStructure = New Structure;
	FillingStructure.Insert("Date", Object.Date);
	FillingStructure.Insert("Currency", Object.Currency);
	FillingStructure.Insert("Partner", Object.Partner);
	FillingStructure.Insert("Terms", Object.Terms);
	FillingStructure.Insert("Organization", Object.Organization);
	FillingStructure.Insert("VATTaxation", Object.VATTaxation);
	FillingStructure.Insert("ReturnReusablePackage", Object.ToReturnReusablePackage);
	FillingStructure.Insert("PopulationFields", "Price, PriceKind");
	
	StructureOfRecalculation = New Structure("Clear", False);
			
	// The structure of the action with the changed strings
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", StructureOfRecalculation);
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(Object.Goods, , FillingStructure, StructureOfActions);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
	Return PricesCalculated;
	
EndFunction

// Resets the prices in the selected document lines according to the selected price type.
//
// Parameters:
// PricesKind - CatalogRef.TypesOfPrices - The type of prices that will be used to fill in prices in PM Products.
//
&AtServer
Function FillInPricesOfSelectedRowsByPriceTypeServer(PricesKind)
	
	RowsArray = New Array;
	For Each String In Items.Goods.SelectedRows Do
		RowsArray.Add(Object.Goods.FindByID(String));
	EndDo;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
			
	FillingStructure = New Structure;
	FillingStructure.Insert("Date", Object.Date);
	FillingStructure.Insert("Organization", Object.Organization);
	FillingStructure.Insert("Currency", Object.Currency);
	FillingStructure.Insert("PriceKind", PricesKind);
	FillingStructure.Insert("PopulationFields", "Price, PriceKind");
	
	StructureOfRecalculation = New Structure("Clear", False);
			
	// The structure of the action with the changed strings
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", StructureOfRecalculation);
			
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(Object.Goods, RowsArray, FillingStructure, StructureOfActions);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
	Return PricesCalculated;
	
EndFunction

#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

// Performs the necessary actions after selection
//
&AtClient
Procedure HandlingSelectionSelectionOnClient(ValueSelected)
	
	ProcessingSelectionOfSelectionOnServer(ValueSelected);
	
EndProcedure

// Performs the necessary actions after selection
//
&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
		
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, "Products, Characteristic, ItemVariantsAreUsed, 
		|Package, NumberOfPackages, Count, PriceKind, Price, Sum, ManualDiscount, PercentRateOfManualDiscount");
		CurrentRow.NumberOfPackagesPlan = RowOfProduct.NumberOfPackages;
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	StructureVariantOfRegistrationOfSale = New Structure("Products", "SaleRegistrationOption");
	StructureCharacteristicsAreUsed = New Structure("Products", "ItemVariantsAreUsed");
	
	StructureAndAttributes = New Structure(
			"FillInFeatureAttribute, FillInSalesOptionAttribute",
			StructureCharacteristicsAreUsed,
			StructureVariantOfRegistrationOfSale);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods,
			StructureAndAttributes);
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

&AtServer
Procedure SetSelectionAvailability()
	
	Items.GoodsOpenSelection.Enabled = (Object.Status = Enums.SalesRepresentativeTaskStatuses.NotPrepared2);
	
EndProcedure

&AtClient
Procedure ReportErrorsWhenOpeningSelection(Cancel)
	
	If ToUseTermsOfSales And Not ValueIsFilled(Object.Terms) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Thỏa thuận""';
												|ru = 'Поле ""Соглашение"" не заполнено';
												|en = '""Terms of sales"" are not filled'; fa = '""Terms of sales"" are not filled';
												|it = 'Il campo ""Accordo"" non è compilato';
												|pl = 'Pole ""Porozumienie"" nie jest wypełnione';
												|tr = '""Anlaşma"" alanı doldurulmamış'"), Object.Ref, "Object.Terms",,Cancel);
	EndIf;
	If Not ValueIsFilled(Object.Currency) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường ""Tiền tệ""';
												|ru = 'Поле ""Валюта"" не заполнено';
												|en = '""Currency"" is required'; fa = '""Currency"" is required';
												|it = 'Il campo ""Valuta"" non è compilato';
												|pl = 'Pole ""Waluta"" nie jest wypełnione';
												|tr = '""Para Birimi"" alanı doldurulmadı'"), Object.Ref, "Object.Currency",,Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("RecalculateNumberOfSuffixUnits","Plan");
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActionsWithAddedStrings.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActionsWithAddedStrings.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActionsWithAddedStrings.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsWithAddedStrings.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, True));
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings,Object);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings,Object);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.ColumnNameQuantity                   = "NumberOfPackagesPlan";
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);

	CalculateTaskTotalsForSalesRepresentative(ThisObject);
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object,StructureOfActionParameters,CachedValues);
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	ToUseTermsOfSales      = GetFunctionalOption("ToUseTermsOfSales");
	UseSimplifiedPaymentScheme     = GetFunctionalOption("UseSimplifiedPaymentSchemeInSales");
	UsePaymentSchedules             = GetFunctionalOption("UsePaymentSchedules");
	ToUseTheTransferOfGoodsToStorage = False;
	ToUseTheTransferOfGoodsToStorage = GetFunctionalOption("UseTransferToCustodyWithRightOfSale");
	
	DocumentCurrency = Object.Currency;
	
	UseVariants = New Structure("Products", "ItemVariantsAreUsed");
	ItemsTypes = New Structure("Products", "ItemsType");
	SalesRegistrationOptions = New Structure("Products", "SaleRegistrationOption");
	Articles = New Structure("Products", "SKU");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", UseVariants);
	StructureOfActions.Insert("FillInProductTypeAttribute_", ItemsTypes);
	StructureOfActions.Insert("FillInSalesOptionAttribute", SalesRegistrationOptions);
	StructureOfActions.Insert("FillInArticleAttribute", Articles);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
	If Not ToUseTermsOfSales Then
		PriceTypeSelectionParameters = SettingsValueCached.ParametersForSelectingDefaultPriceType();
	
		PriceTypeSelectionParameters.PriceIncludesVAT        = Object.PriceIncludesVAT;
		PriceTypeSelectionParameters.UseWhileSellingToCustomers = True;
		PriceTypeSelectionParameters.Status                 = Enums.StatusesOfPriceTypeValidity.Valid;
		
		DefaultPriceType = SettingsValueCached.DefaultPriceType(PriceTypeSelectionParameters);
	EndIf;
	
	FillInCancelFlag();
	UpdateNoReturnableContainerAttribute();
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
	Items.GroupComment.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	FillOperationSelectionList();
	SetAvailabilityOfItemsByOperationServer();
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	
EndProcedure

&AtServer
Procedure SetVisibilityAndAccessibilityOfElements()

	Items.SumPlan.Visible = Not Object.ItemsDetails;
	Items.GoodsCancellationReason.Visible = Object.ItemsDetails;
	Items.CalculateJobAmountAccordingToSalesHistoryData.Visible = Not Object.ItemsDetails;
	Items.FillInTheTaskBasedOnTheSalesHistoryData.Visible = Object.ItemsDetails;

	EstablishVisibilityOfTargets();
	SetSelectionAvailability();

EndProcedure

&AtServer
Procedure EstablishVisibilityOfTargets()
	
	Items.GoodsNumberOfPackagesPlan.Visible = Object.ItemsDetails;

EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByOperationServer()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.JobForSalesRepresentative.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	ProductsServer.SetProductSelectionParameters(Object.BusinessOperation, Items.GoodsProducts);
	
	SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible,
		Object.Contract);
	
EndProcedure

// Opens the base document selection form for selection.
//
// Parameters:
//  TypeOfBase - String - a string indicating the type of base - "task to the trade Representative" or "customer Order".
//
&AtClient
Procedure OpenBaseSelectionForm(TypeOfBase)
	
	FormParameters = New Structure();
	
	FilterStructure1 = New Structure();
	
	If ValueIsFilled(Object.Partner) Then
		FilterStructure1.Insert("Partner", Object.Partner);
	EndIf;
	
	If ValueIsFilled(Object.Counterparty) Then
		FilterStructure1.Insert("Counterparty", Object.Counterparty);
	EndIf;
	
	If ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		FilterStructure1.Insert("Terms", Object.Terms);
	EndIf;
	
	If FilterStructure1.Count()>0 Then
		FormParameters.Insert("Filter", FilterStructure1);
	EndIf;
	
	If TypeOfBase = "JobForSalesRepresentative" Then
		OpenForm("Document.JobForSalesRepresentative.ChoiceForm", FormParameters, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	Else
		OpenForm("Document.SalesOrder.ChoiceForm", FormParameters, ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;	
	
EndProcedure

// Defines the frequency of the virtual table for layout.
//
// Parameters:
//  PeriodAsString - String - the period specified in the fill-in settings.
//
&AtClient
Function GetPeriodForLayout(PeriodAsString)

	If PeriodAsString = "In references_5 for_ aweek" Then
		Return "Week";
	ElsIf PeriodAsString = "In references_5 for_ month" Then
		Return "Month";
	Else
		Return "Day";
	EndIf;

EndFunction

// Determines whether the planned amount should be converted to the specified currency.
//
// Parameters:
//  Currency - CatalogRef.Currencies -the currency that you want to check for conversion to.
//
// Returns:
//  Boolean - True if recalculation is required, False is not required.
//
&AtClient
Function ItIsRequiredToRecalculatePlannedAmount(Currency)
	
	If Not Object.ItemsDetails And Currency <> DocumentCurrency And Object.SumPlan <> 0 And ValueIsFilled(Currency) Then
		Return True;
	Else
		Return False;
	EndIf;	

EndFunction

&AtServer
Procedure FillInDefaultContract()
	
	Object.Contract = SalesServer.GetDefaultContract(Object, Object.BusinessOperation, Object.Currency);
	
EndProcedure

// Recalculates document data when changing the "Currency" details.
//
// Parameters:	
//  NewCurrency - CatalogRef.Currencies - the currency in which you want to recalculate data.
//  OldCurrency - CatalogRef.Currencies - the currency to convert from.
//  RecalculationOfTablePartsIsRequired - Boolean - flag that specifies whether to recalculate table parts.
//  RecalculationOfPlannedAmountIsRequired - Boolean - flag that determines whether the planned amount of the task should be recalculated.
//
&AtServer
Procedure HandlingCurrencySelection(NewCurrency, OldCurrency, RecalculationOfTablePartsIsRequired, RecalculationOfPlannedAmountIsRequired)
	
	If Not RecalculationOfTablePartsIsRequired And Not RecalculationOfPlannedAmountIsRequired Then
		Return;
	EndIf;
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	CourseStructures = ARAPAccountingServer.ExchangeRatesForTranslation(ThisForm, OldCurrency, NewCurrency, LocalAccountingCurrency, Object.Date);
	StructureOfOldCurrencyRates = CourseStructures.StructureOfOldCurrencyRates;
	StructureOfNewCurrencyRates  = CourseStructures.StructureOfNewCurrencyRates;
	
	If RecalculationOfTablePartsIsRequired Then
		
		PriceManagementSystem.ConvertTabularAmountsToCurrency(
			Object.Goods,
			Object.PriceIncludesVAT,
			OldCurrency,
			NewCurrency,
			StructureOfOldCurrencyRates,
			StructureOfNewCurrencyRates,
			False,
			True);
		
		PriceManagementSystem.DistributeAmountByPaymentStages(
			Object,
			Object.Goods.Total("AmountIncludingVATWithoutReusablePackages"),
			PackageDepositValue);
		
	EndIf;
	
	If RecalculationOfPlannedAmountIsRequired Then
		
		Object.SumPlan = ProcessingOfExchangeRatesTM.ConvertAtRate(Object.SumPlan,
                   StructureOfOldCurrencyRates, StructureOfNewCurrencyRates);
		
	EndIf;
	
EndProcedure

// Fills in the detailed task structure based
// on the sales history data.
//
// Parameters:
//  BeginOfPeriod - Date - the beginning of the period for which the sales history is analyzed.
//  EndOfPeriod - Date - end of the period for which the sales history is analyzed.
//  Period - String - the period for which the average sales volume is calculated.
//  CharacteristicsDetails - Boolean - indicates that the composition should be detailed by characteristics.
//  Settings - DataCompositionSettings - the specified settings.
//
&AtServer
Procedure FillInTaskBasedOnSalesHistoryDataServer(BeginOfPeriod, EndOfPeriod, Period, CharacteristicsDetails, Settings)
	
	If Object.ItemsDetails Then
		CompositionSchema = Documents.JobForSalesRepresentative.GetTemplate("LayoutSchemeForAutoFillingWithSalesHistory");
	Else
		CompositionSchema = Documents.JobForSalesRepresentative.GetTemplate("LayoutSchemeForAutoFillingWithSalesHistoryByAmount");
	EndIf;	

	CompositionSettings = CompositionSchema.DefaultSettings;
	
	Address = New UUID();
	URLSchemes = PutToTempStorage(CompositionSchema, Address);
	SettingsSource = New DataCompositionAvailableSettingsSource(URLSchemes);
	
	SettingsComposer = New DataCompositionSettingsComposer;
	
	SettingsComposer.Initialize(SettingsSource);
	SettingsComposer.LoadSettings(Settings);
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);		
	
	CompositionSettings = SettingsComposer.GetSettings();
	
	MobileApps.SetUseOfLayoutField(CompositionSettings, "Characteristic", CharacteristicsDetails);
	MobileApps.SetUseOfLayoutField(CompositionSettings, "CountPlan", True);
	
	MobileApps.SetValueOfSettingsParameter(CompositionSettings, "CharacteristicsDetails", CharacteristicsDetails);
	
	QueryResult = SalesRepresentativesServer.MakeRequestForSalesHistory(
		CompositionSettings,
		BeginOfPeriod,
		EndOfPeriod,
		Period,
		True);
	
	QueryTable = QueryResult.Unload();
	
	Object.Goods.Clear();
	
	For Each CurRow In QueryTable Do
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow,CurRow);
		NewRow.NumberOfPackagesPlan = NewRow.CountPlan;
	EndDo;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	// The fill parameters
	FillingStructure = New Structure;
	FillingStructure.Insert("Date", Object.Date);
	FillingStructure.Insert("Organization", Object.Organization);
	FillingStructure.Insert("Currency", Object.Currency);
	FillingStructure.Insert("Terms", Object.Terms);
	FillingStructure.Insert("VATTaxation", Object.VATTaxation);
	FillingStructure.Insert("ReturnReusablePackage", Object.ToReturnReusablePackage);
	FillingStructure.Insert("PopulationFields", "Price, VATRate, PriceKind");
					
	StructureOfRecalculation = New Structure("Clear", False);
	
	CachedValues = Undefined;
	
	// The structure of the action with the changed strings
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", StructureOfRecalculation);
				
	EnterprisePricesFillingServer.FillInPrices(Object.Goods, , FillingStructure, StructureOfActions);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	
	UseVariants = New Structure("Products", "ItemVariantsAreUsed");
	ItemsTypes = New Structure("Products", "ItemsType");
	SalesRegistrationOptions = New Structure("Products", "SaleRegistrationOption");
	Articles = New Structure("Products", "SKU");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", UseVariants);
	StructureOfActions.Insert("FillInProductTypeAttribute_", ItemsTypes);
	StructureOfActions.Insert("FillInSalesOptionAttribute", SalesRegistrationOptions);
	StructureOfActions.Insert("FillInArticleAttribute", Articles);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInContent", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInServiceContentInTSLine(Object, True));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	FillInCancelFlag();
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
EndProcedure

// Calculates the task amount based on sales history data.
//
// Parameters:
//  BeginOfPeriod - Date - the beginning of the period for which the sales history is analyzed.
//  EndOfPeriod - Date - end of the period for which the sales history is analyzed.
//  Period - String - the period for which the average sales volume is calculated.
//  Settings - DataCompositionSettings - the specified settings.
//
&AtServer
Procedure SetTaskAmountBasedOnSalesHistory(BeginOfPeriod, EndOfPeriod, Period, Settings)
	
	If Object.ItemsDetails Then
		CompositionSchema = Documents.JobForSalesRepresentative.GetTemplate("LayoutSchemeForAutoFillingWithSalesHistory");
	Else
		CompositionSchema = Documents.JobForSalesRepresentative.GetTemplate("LayoutSchemeForAutoFillingWithSalesHistoryByAmount");
	EndIf;	

	CompositionSettings = CompositionSchema.DefaultSettings;
	
	Address = New UUID();
	URLSchemes = PutToTempStorage(CompositionSchema, Address);
	SettingsSource = New DataCompositionAvailableSettingsSource(URLSchemes);
	
	SettingsComposer = New DataCompositionSettingsComposer;
	
	SettingsComposer.Initialize(SettingsSource);
	SettingsComposer.LoadSettings(Settings);
	
	CompositionSettings = SettingsComposer.GetSettings();
	QueryResult = SalesRepresentativesServer.MakeRequestForSalesHistory(
		CompositionSettings,
		BeginOfPeriod,
		EndOfPeriod,
		Period,
		False);
	
	QueryTable = QueryResult.Unload();
	
	SumOfSalesHistory = QueryTable.Total("Sum");
	CurrencyOfManAccounting = Constants.ManagementAccountingCurrency.Get();
	
	If Object.Currency <> CurrencyOfManAccounting Then
		StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(CurrencyOfManAccounting,Object.Date);
		StructureOfNewCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(Object.Currency,Object.Date);
		
		SumOfSalesHistory = ProcessingOfExchangeRatesTM.ConvertAtRate(SumOfSalesHistory,
                     StructureOfOldCurrencyRates, StructureOfNewCurrencyRates);
		
	EndIf;
	
	Object.SumPlan = SumOfSalesHistory;
	
EndProcedure

// Checks whether there are possible collisions when exchanging with the mobile app.
//
// Returns:
//  Boolean - the result of the analysis. True - collisions are possible, False - not.
//
&AtServerNoContext
Function PossibleCollisionsWithMobileApplication(DocumentRef)
	
	QueryText = 
	"SELECT ALLOWED
	|	JobForSalesRepresentative.Status,
	|	SUM(CASE
	|			WHEN JobForSalesRepresentativeChanges.Ref IS NULL 
	|				THEN 0
	|			ELSE 1
	|		END) AS ChangesRegistered
	|FROM
	|	Document.JobForSalesRepresentative AS JobForSalesRepresentative
	|		LEFT JOIN Document.JobForSalesRepresentative.Changes AS JobForSalesRepresentativeChanges
	|		ON (JobForSalesRepresentativeChanges.Ref = JobForSalesRepresentative.Ref)
	|			AND (JobForSalesRepresentativeChanges.Node.User = JobForSalesRepresentative.SalesRepresentative)
	|WHERE
	|	JobForSalesRepresentative.Ref = &Ref
	|
	|GROUP BY
	|	JobForSalesRepresentative.Status"
	;
	
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentRef);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		If Selection.Status = Enums.SalesRepresentativeTaskStatuses.Processed_
			Or (Selection.Status = Enums.SalesRepresentativeTaskStatuses.ToProcessing And Selection.ChangesRegistered=0) Then
			Return True;
		EndIf;
	EndIf;
	
	Return False;

EndFunction

&AtServer
Procedure ProcessFillingBasedOn(DocumentBasis)
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Fill(DocumentBasis);
	ValueToFormAttribute(DocumentObject, "Object");
	
	UseVariants = New Structure("Products", "ItemVariantsAreUsed");
	ItemsTypes = New Structure("Products", "ItemsType");
	SalesRegistrationOptions = New Structure("Products", "SaleRegistrationOption");
	Articles = New Structure("Products", "SKU");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", UseVariants);
	StructureOfActions.Insert("FillInProductTypeAttribute_", ItemsTypes);
	StructureOfActions.Insert("FillInSalesOptionAttribute", SalesRegistrationOptions);
	StructureOfActions.Insert("FillInArticleAttribute", Articles);
			
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
	UpdateNoReturnableContainerAttribute();
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);

EndProcedure

&AtServer
Procedure FillInCancelFlag()
	
	For Each String In Object.Goods Do
		String.Canceled = ValueIsFilled(String.CancellationReason);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateNumberOfSuffixUnits","Plan");
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
EndProcedure

&AtClientAtServerNoContext
Function DependentDetails()
	
	Return New Structure(
		"WithoutReusablePackages,CanceledWithoutReusablePackages,Canceled",
		"Sum,VATAmount,AmountIncludingVAT,ManualDiscount",
		"Sum,VATAmount,AmountIncludingVAT,ManualDiscount",
		"Sum,VATAmount,AmountIncludingVAT,ManualDiscount");
	
EndFunction

&AtClientAtServerNoContext
Procedure CalculateTaskTotalsForSalesRepresentative(Form)
	
	// Filling in the totals according to the "Products" table
	
	CollectionProducts = Form.Object.Goods;
	
	Form.AmountOrdered = ?(Form.Object.PackageDepositIsRequired,
		Form.Object.Goods.Total("AmountIncludingVAT") - Form.Object.Goods.Total("AmountIncludingVATCanceled"),
		Form.Object.Goods.Total("AmountIncludingVATWithoutReusablePackages") - Form.Object.Goods.Total("AmountIncludingVATCanceledWithoutReusablePackages"));
	Form.PackageDepositValue = ?(Form.Object.PackageDepositIsRequired,(CollectionProducts.Total("AmountIncludingVAT") - CollectionProducts.Total("AmountIncludingVATCanceled"))
			- (CollectionProducts.Total("AmountIncludingVATWithoutReusablePackages") - CollectionProducts.Total("AmountIncludingVATCanceledWithoutReusablePackages")),0);
	Form.AmountNDSOrdered = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("VATAmount") - CollectionProducts.Total("VATAmountCanceled"),
		CollectionProducts.Total("VATAmountWithoutReusablePackages") - CollectionProducts.Total("VATAmountCanceledWithoutReusablePackages"));
	Form.ManualDiscount = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("ManualDiscount") - CollectionProducts.Total("ManualDiscountCanceled"),
		CollectionProducts.Total("ManualDiscountWithoutReusablePackages") - CollectionProducts.Total("ManualDiscountCanceledWithoutReusablePackages"));
	Form.DiscountAmount = Form.ManualDiscount;
	Form.SumCanceled = ?(Form.Object.PackageDepositIsRequired,
		CollectionProducts.Total("SumCanceled"),
		CollectionProducts.Total("SumCanceledWithoutReusablePackages"));
	
	AmountOrdered = ?(Form.Object.PackageDepositIsRequired,
		Form.Object.Goods.Total("AmountIncludingVAT") - Form.Object.Goods.Total("AmountIncludingVATCanceled"),
		Form.Object.Goods.Total("AmountIncludingVATWithoutReusablePackages") - Form.Object.Goods.Total("AmountIncludingVATCanceledWithoutReusablePackages"));
	
	If AmountOrdered > 0 Then
		Form.PercentRateOfManualDiscount = Form.ManualDiscount * 100 / (AmountOrdered + Form.DiscountAmount);
		Form.DiscountPercentage       = Form.PercentRateOfManualDiscount;
	ElsIf Form.DiscountAmount > 0 Then
		Form.PercentRateOfManualDiscount = Form.ManualDiscount * 100 / Form.DiscountAmount;
		Form.DiscountPercentage       = Form.PercentRateOfManualDiscount;
	Else
		Form.PercentRateOfManualDiscount = 0;
		Form.DiscountPercentage       = 0;
	EndIf;
	
	// Filling in the totals by payment stages
	
	Form.AmountPrepaymentBeforeGoodsIssue = 0;
	Form.AmountOfPrepaymentBeforeShipment = 0;
	Form.CreditAmountAfterShipment = 0;
	Form.PercentageOfAdvancePaymentBeforeCollateral = 0;
	Form.PrepaymentPercentageBeforeShipment = 0;
	Form.CreditPercentageAfterShipment = 0;
	
	MatchingPaymentOptions = New Map;
	MatchingPaymentOptions.Insert(PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision"),
		New Structure("Sum, Interests", "AmountPrepaymentBeforeGoodsIssue", "PercentageOfAdvancePaymentBeforeCollateral"));
	MatchingPaymentOptions.Insert(PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment"),
		New Structure("Sum, Interests", "AmountOfPrepaymentBeforeShipment", "PrepaymentPercentageBeforeShipment"));
	MatchingPaymentOptions.Insert(PredefinedValue("Enum.CustomerPaymentControlOptions.CreditPlanned"),
		New Structure("Sum, Interests", "CreditAmountAfterShipment", "CreditPercentageAfterShipment"));
	
	For Each CurRow In Form.Object.PaymentScheduleSteps Do
		ItemsNames = MatchingPaymentOptions[CurRow.PaymentOption];
		If ItemsNames <> Undefined Then
			Form[ItemsNames.Sum] = Form[ItemsNames.Sum] + CurRow.PaymentAmount;
			Form[ItemsNames.Interests] = Form[ItemsNames.Interests] + CurRow.PaymentPercentage;
		EndIf;
	EndDo;
	
	// Selecting the VAT display page
	DisplayTotalAmountOfVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation);
	
	If DisplayTotalAmountOfVAT Then
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	Else
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	EndIf;
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	PlacePaymentStepsInTemporaryStorage(Item.Name);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing, Notification );
EndProcedure

&AtServer
Procedure PlacePaymentStepsInTemporaryStorage(TagName)
	PaymentStepsServer.PlacePaymentStepsInTemporaryStorage(ThisForm, TagName);
EndProcedure

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	PaymentStepsServer.LoadPaymentStagesFromTemporaryStorage(ThisForm);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	If Result <> Undefined Then
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
	ReflectChangesToPaymentRules(ChangedBankingDetails);
	EndIf;
EndProcedure

&AtServer
Function AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(SelectedLinesOnly)
	
	ParametersStructure = DiscountsMarkupsFillingServer.NewParametersAddressDataForCalculatingManualDiscounts();
	ParametersStructure.TableName = "Goods";
	ParametersStructure.OnlyForSelectedLines = SelectedLinesOnly;
	Return DiscountsMarkupsFillingServer.AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(
		ThisForm, UUID, ParametersStructure);
	
EndFunction

&AtServer
Procedure FillIn_TermsOfSales()
	
	PaymentSchedule = Object.PaymentSchedule;
	Terms   = Object.Terms;
	
	DocumentSales = FormAttributeToValue("Object");
	DocumentSales.FillInDefaultTermsOfService();
	DocumentSales.FillInDefaultSalesConditions();
	
	ValueToFormData(DocumentSales,Object);
	
	If ToUseTermsOfSales
		And Terms <> Object.Terms
		And ValueIsFilled(Object.Terms) Then
		
		WhenChangingAgreementAtServer(False);
		
	Else
		SalesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	EndIf;
	
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	FillParameters = Documents.JobForSalesRepresentative.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateAvailabilityOfReturnContainerItems(Form)
	
	ItemArray = New Array();
	ItemArray.Add("ReusablePackageReturnCycleLength");
	ItemArray.Add("PackageDepositIsRequired");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Form.Items, ItemArray, "Enabled", Form.Object.ToReturnReusablePackage);
	
EndProcedure

&AtServer
Procedure FillMultiTurnContainersFromStorageServer(AddressOfContainerInStorage)
	
	ActionStructureModifiedStrings = New Structure();
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	ActionStructureModifiedStrings.Insert("RecalculateNumberOfPackages");
	ActionStructureModifiedStrings.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	ActionStructureModifiedStrings.Insert("RecalculateAmount");
	ActionStructureModifiedStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	ActionStructureModifiedStrings.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	ActionStructureModifiedStrings.Insert("FillInDuplicateDependentDetails", DependentDetails());
	
	StructureOfActionsAddedLines =  CommonClientServer.CopyStructure(ActionStructureModifiedStrings);;
	StructureOfActionsAddedLines.Insert("FillInSalesOptionAttribute", New Structure("Products", "SaleRegistrationOption"));
	If (ToUseTermsOfSales And ValueIsFilled(Object.Terms)) 
		Or (Not ToUseTermsOfSales And UsePriceManagementSystem25) Then
		StructureOfActionsAddedLines.Insert("FillIn_TermsOfSales", BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	Else
		StructureOfActionsAddedLines.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	StructureOfActionsAddedLines.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsAddedLines.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsAddedLines.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActionsAddedLines.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActionsAddedLines.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActionsAddedLines.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	
	ReusablePackageServer.FillMultiTurnContainersFromStorage(
		Object,
		AddressOfContainerInStorage,
		"Goods",
		"Products,Characteristic",
		ActionStructureModifiedStrings,
		StructureOfActionsAddedLines);
		
	UsageStructure = New Structure("Products", "ItemVariantsAreUsed");
	UseVariants = New Structure("FillInFeatureAttribute", UsageStructure);
			
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, UseVariants);
	
EndProcedure

&AtServer
Procedure ToReturnReusablePackageOnChangeServer()
	
	If Not Object.ToReturnReusablePackage Then
		Object.PackageDepositIsRequired = False;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, Undefined);
	
	TMCommonUse.FillInDuplicateDependentPropsInCollection(Object.Goods, DependentDetails());
	UpdateAvailabilityOfReturnContainerItems(ThisForm);
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	
EndProcedure

&AtServer
Procedure UpdateNoReturnableContainerAttribute()
	
	StructureOfAdditionalActions = New Structure;
	StructureOfAdditionalActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	ReusablePackageServer.UpdateNoReturnableContainerAttribute(Object.Goods, Object.ToReturnReusablePackage, StructureOfAdditionalActions);
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
EndProcedure

&AtServer
Procedure FillOperationSelectionList()

	If Items.Find("BusinessOperation") <> Undefined Then
	
		If Not GetFormFunctionalOption("UseSalesCommission") Then
			
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(Enums.BusinessTransactions.TransferToCommissionAgent);
			If ListItem <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ListItem);
			EndIf;
			
		EndIf;
		
		If Not ToUseTheTransferOfGoodsToStorage Then
			ListItem = Items.BusinessOperation.ChoiceList.FindByValue(
				Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
			
			If ListItem <> Undefined Then
				Items.BusinessOperation.ChoiceList.Delete(ListItem);
			EndIf;
		EndIf;
		
		OnlyOperation = Items.BusinessOperation.ChoiceList.Count() = 1;
		TMCommonUseClientServer.SetFormItemProperty(
			Items,
			"BusinessOperation",
			"ReadOnly",
			OnlyOperation And ValueIsFilled(Object.BusinessOperation));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	FillInVATRateOnServer(VATRate, CachedValues);

EndProcedure

&AtServer
Procedure FillInVATRateOnServer(VATRate, CachedValues)

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("FillInDuplicateDependentDetails", DependentDetails());

	SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(
		Object.Goods, Items.Goods.SelectedRows);
	
	For Each LineOfATabularSection In SelectedRows Do
		LineOfATabularSection.VATRate = VATRate;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		SelectedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	CalculateTaskTotalsForSalesRepresentative(ThisObject);

EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale") Then
		
		FilterParameters = New Map;
		FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductMultiTurnContainer());
	Else
		FilterParameters = Undefined;
	EndIf;
	
	Columns = "Products,Characteristic,Package,NumberOfPackages,PriceKind,Price,
		|PercentRateOfManualDiscount,ManualDiscount";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInVATRate",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
		
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInNoReturnContainerAttribute", Object.ToReturnReusablePackage);
	StructureOfActions.Insert("FillInCanceledWithoutReturnableContainerAttribute", Object.ToReturnReusablePackage);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);
	If TableOfGoods.Columns.Find("ManualDiscount") <> Undefined Then
		StructureOfActions.RecalculateAmountTakingIntoAccountManualDiscount.Insert("RecalculateAmountOfManualDiscount_", False);
	EndIf;
	
	ParametersForFillingInPriceType = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceTypeInTSLine("PriceKind");
	ParametersForFillingInPriceType.FilterParameters.PriceIncludesVAT = Object.PriceIncludesVAT;
	ParametersForFillingInPriceType.FilterParameters.UseWhileSellingToCustomers = True;
	StructureOfActions.Insert("CheckFillInPriceView", ParametersForFillingInPriceType);
	
	StructureOfActions.Insert("FillInSalePrice",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		CurrentRow.NumberOfPackagesPlan = CurrentRow.NumberOfPackages;
		If Not UseDiscountAdjustmentsInSales Then
			CurrentRow.PercentRateOfManualDiscount = 0;
			CurrentRow.ManualDiscount = 0;
		EndIf;
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	UseVariants = New Structure("Products", "ItemVariantsAreUsed");
	SalesRegistrationOptions =  New Structure("Products", "SaleRegistrationOption");
	
	StructureOfActions = New Structure(
			"FillInFeatureAttribute, FillInSalesOptionAttribute",
			UseVariants,
			SalesRegistrationOptions);
			
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
	CalculateTaskTotalsForSalesRepresentative(ThisForm);
	ReusablePackageServer.UpdateFillingStateOfMultiTurnContainer(Object.ReusablePackageFillingStatus);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("GoodsInsertRows");
	ItemArray.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure


// End StandardSubsystems.Properties

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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
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
