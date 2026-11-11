
#Region Variables

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If TypeOf(Parameters.Basis) = Type("DocumentRef.ReceiptOfCashRegisterAdjustment")
		And ValueIsFilled(Parameters.Basis) Then
		
		MessageText = NStr("vi = 'Sao chép chứng từ ""Kiểm tra chỉnh sửa Phiếu tính tiền"" đều bị cấm!';
							|ru = 'Копирование документа ""Чек ККМ коррекции"" запрещено!';
							|en = 'Copying of the ""Cash register adjustment voucher"" document is not allowed!'; fa = 'Copying of the ""Cash register adjustment voucher"" document is not allowed!';
							|it = 'È vietato copiare il documento ""Scontrino di registratore di cassa di correzione""!';
							|pl = 'Kopiowanie dokumentu""Paragon kasy korekty"" jest zabronione!';
							|tr = '""Yazar kasa düzeltme fişi"" belgesi kopyalanamaz!'");
		CommonClientServer.MessageToUser(MessageText);
		
		Cancel = True;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ReceiptOfCashRegisterAdjustment));
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters); 
		SetVisibilityOfSeriesElements();
		FillInServiceDetailsForProductRange();
		Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
		
	EndIf;
	
	ToFormInitialFillingOfReceiptOfKKMGoods();
	CalculateIntroducedDiscrepancies();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	SetPresentationOfFoundationDocument();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	SetValuesBySettings();
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormToPunchTheCorrectionReceipt", "Enabled",
		AccessRight("Update", Metadata.Documents.ReceiptOfCashRegisterAdjustment));
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormPostAndClose", "Enabled",
		AccessRight("Update", Metadata.Documents.ReceiptOfCashRegisterAdjustment));
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormWriteDocument", "Enabled",
		AccessRight("Update", Metadata.Documents.ReceiptOfCashRegisterAdjustment));
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormPostDocument", "Enabled",
		AccessRight("Update", Metadata.Documents.ReceiptOfCashRegisterAdjustment));
		
	If Object.Status = Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_ Then
		ReadOnly = True;
	Else
		ReadOnly = False;
	EndIf;
	
	AdjustTypeOfCorrection();
	
	Items.Goods.ReadOnly = Not (Object.TypeOfCorrection = Enums.KindsOfAdjustmentReceipts.CorrectionOfErrors);
	Items.GoodsPremise.Visible = WarehousesServer.UseWarerooms(Object.Warehouse,Object.Date);
	Items.DiscrepancyPage.Visible = (Object.TypeOfCorrection = Enums.KindsOfAdjustmentReceipts.CorrectionOfErrors);
	
	If Object.Status <> Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_ Then
		Items.GroupDeliveryAmount.Visible = False;
	EndIf;
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	RecalculateDocumentOnClient();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	SetAvailabilityOfCorrectionAttributes();
	SetVisibilityOfButtonFiscalizationOfCorrectionReceipt();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ReceiptOfCashRegisterAdjustment));
	SetVisibilityOfSeriesElements();
	FillInServiceDetailsForProductRange();
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	SetPresentationOfFoundationDocument();

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	FillInServiceDetailsForProductRange();
	
	If Not WriteParameters.Property("TransactionMode") Or Not WriteParameters.TransactionMode Then
		// StandardSubsystems.AccessManagement
		AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
		// End StandardSubsystems.AccessManagement
		
		ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
		ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	StandardProcessing = False;
	
	If Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_") Then
		Return;
	EndIf;
	
	If Exit Then
		Return;
	EndIf;
	
	BeforeClosingReceipt(Cancel);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ErrorDuringReceiptIssueCompletion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Cancel Then
		
		RetryRecordingIsRequired = False;
		OperationResult = AdditionalParameters.OperationResult;
		If AdditionalParameters.ProcedureName = "RecordFiscalTransactionOnServer" Then
			OperationResult = RecordFiscalTransactionOnServer(RetryRecordingIsRequired, AdditionalParameters.DetailsOfCashNodeSFiscalOperation);
		EndIf;
		
		If (TypeOf(OperationResult) = Type("Boolean") And OperationResult)
			Or (TypeOf(OperationResult) = Type("Structure") And OperationResult.Property("CalculationCompletedSuccessfully") And OperationResult.CalculationCompletedSuccessfully) Then
			
			RunCallback(
				AdditionalParameters.CallbackDescription,
				?(AdditionalParameters.ReturnFunctionResult, OperationResult, AdditionalParameters.ResultOfSuccessfulImplementation));
			
		Else
			
			ShowQueryBox(
				New CallbackDescription("ErrorDuringReceiptIssueCompletion", ThisObject, AdditionalParameters),
				AdditionalParameters.MessageText,
				QuestionDialogMode.RetryCancel, 10, DialogReturnCode.Retry,,DialogReturnCode.Retry);
			
		EndIf;
		
	Else
		
		RunCallback(
			AdditionalParameters.CallbackDescription,
			?(AdditionalParameters.ReturnFunctionResult, AdditionalParameters.OperationResult, AdditionalParameters.CancellationResult_));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateCashShift()
	
	StructureRegisterShiftState = RetailSales.GetCashShiftState(Object.CashRegister);
	If Object.CashRegisterShift <> StructureRegisterShiftState.CashRegisterShift Then
		Object.CashRegisterShift = StructureRegisterShiftState.CashRegisterShift;
	EndIf;
	
EndProcedure

&AtClient
Procedure PushReceiptProcessingNotifications(Result, AdditionalParameters) Export
	
	If Not (Result And Object.Posted) Then
		Return;
	EndIf;
	
	UpdateCashShift();
	
	FiscalOperationData = FiscalOperationData();
	DetailsOfTheCashier = DetailsOfTheCashier();
	
	ParametersOfReceiptFiscalizationOperation = ParametersOfReceiptFiscalizationOperation();
	ConductFormatAndLogicalControlLocalization(ParametersOfReceiptFiscalizationOperation, CashRegisterParameters.DeviceID);
	
	PunchReceiptAfterTransaction(ParametersOfReceiptFiscalizationOperation);
	
EndProcedure

&AtClient
Procedure FiscalizationOfAdjustmentCashReceipt(Command)
	
	PostIssueReceipt();
	
EndProcedure

&AtClient
Procedure SetVisibilityOfButtonFiscalizationOfCorrectionReceipt()
	
	If Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_") Then
		Items.FormToPunchTheCorrectionReceipt.Visible = False;
	Else
		Items.FormToPunchTheCorrectionReceipt.Visible = True;
	EndIf;
	
	If GeneratingFiscalChecksServerCall.ParametersOfReceiptFiscalizationOperation(Object.Ref, Object.Organization) = Undefined Then
		Items.FormToPunchTheCorrectionReceipt.Enabled = False;
	Else
		Items.FormToPunchTheCorrectionReceipt.Enabled = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentTypeOnChange(Item)
	
	If Object.AdjustmentType = PredefinedValue("Enum.TypesOfAdjustmentReceipts.ByPrescription") Then
		Object.AdjustmentDescription = Undefined;
	Else
		Object.PrescriptionNumberOfTaxAuthority = Undefined;
	EndIf;
	
	SetAvailabilityOfCorrectionAttributes();
	
EndProcedure

&AtClient
Procedure TypeOfCorrectionOnChange(Item)
	
	If Object.TypeOfCorrection = PredefinedValue("Enum.KindsOfAdjustmentReceipts.CRENonApplication") Then
		Object.AdjustmentDescription = NStr("vi = 'Không sử dụng MTT';
											|ru = 'Неприменение ККТ';
											|en = 'Cash register non-application'; fa = 'عدم استفاده از صندوق فروش';
											|it = 'Mancata applicazione del turno registratore di cassa';
											|pl = 'Niestosowanie kasy';
											|tr = 'Yazar kasa kullanılmaması'"); 
	Else
		Object.AdjustmentDescription = "";
	EndIf;
	
	Items.Goods.ReadOnly =
		Not (Object.TypeOfCorrection = PredefinedValue("Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors"));
	Items.DiscrepancyPage.Visible =
		(Object.TypeOfCorrection = PredefinedValue("Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors"));
	
	SetAvailabilityOfCorrectionAttributes();
	
EndProcedure

&AtClient
Procedure BaseDocumentPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		ShowValue(Undefined, Object.CashRegisterReceipt);
	EndIf;
	
EndProcedure

#EndRegion

#Region Posting

&AtClient
Procedure ProcessRecordingMode()
	
	ShowQueryBox(
		New CallbackDescription("AfterAnsweringQuestionAboutDocumentEntry", ThisObject),
		NStr("vi = 'Giao dịch chỉ có thể sau khi kết chuyển chứng từ, kết chuyển chứng từ?';
			|ru = 'Операция возможна только после проведения документа, провести документ?';
			|en = 'The operation is possible only after posting the document. Post the document?'; fa = 'The operation is possible only after posting the document. Post the document?';
			|it = 'L''operazione è possibile solo dopo la registrazione del documento in contabilità, pubblicare il documento?';
			|pl = 'Operacja jest możliwa tylko po zaksięgowaniu dokumentu, zaksięgować dokument?';
			|tr = 'İşlem yalnızca bir belge kaydedildikten sonra mümkündür, belgeyi kaydedilsin mi?'"),
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure AfterAnsweringQuestionAboutDocumentEntry(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		WriteObject(
			ThisForm,
			DocumentWriteMode.Posting,
			New CallbackDescription("BreakingThroughReceiptAfterWritingDocument", ThisObject));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteObject(Form, Var_DocumentWriteMode, CallbackDescription)
	
	ResponseViaNotificationDescription = TMCommonUseClientServer.HasObjectAttribute(Form, "NotExecuteCheck1BeforeWrite");
	
	Posted = False;
	Try
		
		If ResponseViaNotificationDescription Then
			
			Form.Write(
				New Structure(
					"WriteMode, ActionAfterRecording",
					Var_DocumentWriteMode,
					CallbackDescription));
			
		Else
			
			Posted = Form.Write(
				New Structure(
					"WriteMode",
					Var_DocumentWriteMode));
			
		EndIf;
		
	Except
		
		Posted = False;
		
	EndTry;
	
	If Not ResponseViaNotificationDescription Then
		RunCallback(CallbackDescription, Posted);
	EndIf;
	
EndProcedure

&AtClient
Procedure BreakingThroughReceiptAfterWritingDocument(Result, AdditionalParameters) Export
	
	If Object.Posted Then
		IssueCashReceipt();
	EndIf; 
	
EndProcedure

#EndRegion

#Region FiscalTransaction

&AtClient
Function RecordFiscalTransactionOnClient(RetryRecordingIsRequired, FiscalizationParameters)
	
	Result = RecordFiscalTransactionOnServer(RetryRecordingIsRequired, FiscalizationParameters);
	
	Return Result;
EndFunction

&AtServer
Function RecordFiscalTransactionOnServer(RetryRecordingIsRequired, FiscalizationParameters)

	WriteParameters = New Structure;
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	WriteParameters.Insert("PostingMode", DocumentPostingMode.RealTime);
	WriteParameters.Insert("TransactionMode", True);

	Result = RetailSales.RecordFiscalTransactionOnServer(ThisObject, FiscalizationParameters, WriteParameters);
	
	If Result Then
		WriteParameters.Insert("TransactionMode", False);
		AfterWriteAtServer(FormAttributeToValue("Object"), WriteParameters);
		FiscalOperationUpdateStatus();
	Else
		RetryRecordingIsRequired = True;
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ReceiptOfCashRegisterAdjustment));
		FillInServiceDetailsForProductRange();
	EndIf;
		
	Return Result;
EndFunction

&AtClient
Procedure CheckMarkingCodeByMeansOfKKT(ParametersOfReceiptFiscalizationOperation)
	
	ReceiptPositions = ParametersOfReceiptFiscalizationOperation.ReceiptPositions;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ParametersOfReceiptFiscalizationOperation", ParametersOfReceiptFiscalizationOperation);
	
	CallbackOnCompletion = New CallbackDescription("CheckMarkingCodeByMeansOfKKTCompletion", ThisObject, AdditionalParameters);
	
	ButtonText = NStr("vi = 'Đánh phiếu';
						|ru = 'Пробить чек';
						|en = 'Issue cash receipt'; fa = 'صدور رسید نقدی';
						|it = 'Emettere lo scontrino';
						|pl = 'Wydrukuj paragon';
						|tr = 'Tahsilat fişi kesin'");
	RetailSalesClient.CheckMarkingCodeByMeansOfKKT(ReceiptPositions, ThisObject, ButtonText, CallbackOnCompletion);
	
EndProcedure

&AtClient
Procedure CheckMarkingCodeByMeansOfKKTCompletion(Result, AdditionalParameters) Export
	
	CheckMarkingCodeByMeansOfKKTCompletionLocalization(Result, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure CheckMarkingCodeByMeansOfKKTCompletionLocalization(Result, AdditionalParameters)
	
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure FiscalOperationStatusURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	FiscalOperationNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region EventHandlersForTablePartGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If SetsClient.ItemToLock(Field) Then
		
		CurrentRow = Object.Goods.FindByID(RowSelected);
		If ValueIsFilled(CurrentRow.ProductsInSet) Then
			
			NotificationParameter1 = New Structure;
			NotificationParameter1.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
			NotificationParameter1.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
			NotificationParameter1.Insert("OwnerForm", UUID);
			
			Notify("EditSet", NotificationParameter1, ThisForm);
			
		EndIf;
		
	ElsIf Field = Items.GoodsProductsInSet Then
		ShowValue(Undefined, Items.Goods.CurrentData.ProductsInSet);
	ElsIf Object.TypeOfCorrection = PredefinedValue("Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors")
		And (Field = Items.GoodsBatchesIndicationStatus Or Field = Items.GoodsSeries) Then
		
		OpenSelectionOfSeries();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeRowChange(Item, Cancel)
	
	If ChangingProducts(Item.CurrentItem.Name)
		And Not AllowedToChangeProducts(Item.CurrentData.Products) Then
		
		MessageText = NStr("vi = 'Sửa chữa các sản phẩm dán nhãn bị cấm. Đối với mặt hàng này, chỉ có thể thay đổi thuế suất Thuế GTGT.';
							|ru = 'Корректировка маркированной продукции запрещена. По данной номенклатуре можно изменять только ставку НДС.';
							|en = 'Adjusting entry of marked products is not permitted. For this item, only the VAT rate can be changed.'; fa = 'Adjusting entry of marked products is not permitted. For this item, only the VAT rate can be changed.';
							|it = 'La correzione di prodotti marcati è vietata. Per questi articoli si può modificare solo l''aliquota IVA.';
							|pl = 'Korekta produkcji znakowanej jest zabroniona. W tej nomenklaturze można zmienić tylko stawkę VAT.';
							|tr = 'Etiketli ürünlerin düzenlenmesine izin verilmez. Bu öğe için sadece KDV oranı değiştirilebilir.'");
		CommonClientServer.MessageToUser(MessageText);
		
		Cancel = True;
		
	Else
		
		CurrentNomenclature = Item.CurrentData.Products;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If Not AllowedToChangeProducts(CurrentRow.Products) Then
		
		ClearMessages();
		
		CurrentRow.Products = CurrentNomenclature;
		
		MessageText = NStr("vi = 'Điều chỉnh các sản phẩm rượu và thuốc lá đều bị cấm.';
							|ru = 'Корректировка алкогольной и табачной продукции запрещена.';
							|en = 'Adjustment of alcohol containing and tobacco products is prohibited.'; fa = 'Adjustment of alcohol containing and tobacco products is prohibited.';
							|it = 'La correzione dell''inserimento dei prodotti alcolici e del tabacco è vietata.';
							|pl = 'Korekta wyrobów alkoholowych i tytoniowych jest zabroniona.';
							|tr = 'Alkol ve tütün düzenlemeleri yasaktır.'");
		CommonClient.MessageToUser(MessageText);
	Else	
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
		StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, Items.GoodsProducts.Name, StructureOfActions);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value                   = CurrentRow.Series;
	ValueSelected.CurrentRowID = CurrentRow.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
	StructureOfRecalculationParameters = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	CurrentRow.Price = CalculatePrice(CurrentRow.Sum, CurrentRow.NumberOfPackages, CurrentRow.VATAmount, StructureOfRecalculationParameters.PriceIncludesVAT)
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateIntroducedDiscrepancies();
	
EndProcedure

&AtClient
Procedure GoodsConsignorOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;
	
	If Not AllowedToChangeProducts(CurrentRow.Products) Then
		
		ClearMessages();
		
		CurrentRow.Products = CurrentNomenclature;
		
		MessageText = NStr("vi = 'Điều chỉnh các sản phẩm rượu và thuốc lá đều bị cấm.';
							|ru = 'Корректировка алкогольной и табачной продукции запрещена.';
							|en = 'Adjustment of alcohol-containing and tobacco products is prohibited.'; fa = 'Adjustment of alcohol-containing and tobacco products is prohibited.';
							|it = 'La correzione dell''inserimento dei prodotti alcolici e del tabacco è vietata.';
							|pl = 'Korekta wyrobów alkoholowych i tytoniowych jest zabroniona.';
							|tr = 'Alkol ve tütün düzenlemeleri yasaktır.'");
		CommonClient.MessageToUser(MessageText);
	Else
		
		GoodsConsignorOnChangeLocalization(Item);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

#EndRegion

#Region OnChangeAttributes

&AtClient
Procedure SetAvailabilityOfCorrectionAttributes()
	
	If Object.AdjustmentType = PredefinedValue("Enum.TypesOfAdjustmentReceipts.ByPrescription") Then
		Items.PrescriptionNumberOfTaxAuthority.Enabled = True;
		Items.AdjustmentDescription.Enabled = False;
	Else
		Items.PrescriptionNumberOfTaxAuthority.Enabled = False;
		Items.AdjustmentDescription.Enabled = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsBatchesIndicationStatus.Visible  = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible                = SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	ProductsServer.ProcessSeriesIndication_(Object, SeriesSpecificationParameters, ParametersOfSeriesIndicationForm);

EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisForm);
	
EndFunction

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters,Text, CurrentData)Then
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;

		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,ParametersOfSeriesIndicationForm,ThisForm,,,, New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm)), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
    
    ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
    
    
    ReturnValue_1 = Result;
    
    If ReturnValue_1 <> Undefined Then
        ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm);
    EndIf;

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "DiscrepanciesProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Discrepancies.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisForm,
		"DiscrepanciesCharacteristic",
		"Discrepancies.ItemVariantsAreUsed"
	);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, False);
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisForm, 
		False,
		"DiscrepanciesSeries",
		"Discrepancies.BatchesIndicationStatus",
		"Discrepancies.ItemsType"
	);

	//

	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisForm, False);
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(
		ThisForm,
		False,	
		"DiscrepanciesBatchesIndicationStatus",
		"Discrepancies.BatchesIndicationStatus"
	);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	FiscalOperationUpdateStatus();
	
EndProcedure

&AtServer
Procedure ToFormInitialFillingOfReceiptOfKKMGoods()
	
	If Not ValueIsFilled(Object.CashRegisterReceipt) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "SELECT
	|	CashRegisterReceiptGoods.LineNumber AS LineNumber,
	|	CashRegisterReceiptGoods.ConnectionKey,
	|	CashRegisterReceiptGoods.Consignor AS Consignor,
	|	CashRegisterReceiptGoods.Products AS Products,
	|	CashRegisterReceiptGoods.Products.ItemsType AS ItemsType,
	|	CASE
	|		WHEN
	|			CashRegisterReceiptGoods.Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ItemVariantsAreUsed,
	|	CashRegisterReceiptGoods.Products.UnitOfMeasure AS ProductsUnitOfMeasure,
	|	CashRegisterReceiptGoods.Characteristic AS Characteristic,
	|	CashRegisterReceiptGoods.Package AS Package,
	|	CashRegisterReceiptGoods.NumberOfPackages AS NumberOfPackages,
	|	CashRegisterReceiptGoods.Count AS Count,
	|	CashRegisterReceiptGoods.Price AS Price,
	|	CashRegisterReceiptGoods.Sum AS Sum,
	|	CashRegisterReceiptGoods.VATRate AS VATRate,
	|	CashRegisterReceiptGoods.VATAmount AS VATAmount,
	|	CashRegisterReceiptGoods.PercentRateOfAutomaticDiscountMarkup AS PercentRateOfAutomaticDiscountMarkup,
	|	CashRegisterReceiptGoods.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	CashRegisterReceiptGoods.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
	|	CashRegisterReceiptGoods.ManualDiscount AS ManualDiscount,
	|	CashRegisterReceiptGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	CashRegisterReceiptGoods.Seller AS Seller,
	|	CashRegisterReceiptGoods.Premise AS Premise,
	|	CashRegisterReceiptGoods.Series AS Series,
	|	CashRegisterReceiptGoods.AmountOfBonusPointsToDeduction AS AmountOfBonusPointsToDeduction,
	|	CashRegisterReceiptGoods.AmountOfBonusPointsToDeductionInCurrency AS AmountOfBonusPointsToDeductionInCurrency,
	|	CashRegisterReceiptGoods.AmountOfEarnedBonusPointsInCurrency AS AmountOfEarnedBonusPointsInCurrency,
	|	CashRegisterReceiptGoods.ProductsInSet AS ProductsInSet,
	|	CashRegisterReceiptGoods.ItemVariantOfSet AS ItemVariantOfSet,
	|	CashRegisterReceiptGoods.Barcode AS Barcode,
	|	CashRegisterReceiptGoods.RowID AS RowID,
	|	CashRegisterReceiptGoods.USAISProducts AS USAISProducts
	|FROM
	|	Document.CashRegisterReceipt.Goods AS CashRegisterReceiptGoods
	|WHERE
	|	CashRegisterReceiptGoods.Ref = &Ref
	|
	|ORDER BY
	|	LineNumber";
	Query.SetParameter("Ref", Object.CashRegisterReceipt);
	Selection = Query.Execute().Select();
	
	ArrayOfAttributesToExcludeWhenFillingIn = New Array;
	ArrayOfAttributesToExcludeWhenFillingIn.Add(Metadata.Documents.CashRegisterReceipt.TabularSections.Goods.Attributes.NumberOfPackages.Name);
	ArrayOfAttributesToExcludeWhenFillingIn.Add(Metadata.Documents.CashRegisterReceipt.TabularSections.Goods.Attributes.Price.Name);
	ArrayOfAttributesToExcludeWhenFillingIn.Add(Metadata.Documents.CashRegisterReceipt.TabularSections.Goods.Attributes.VATAmount.Name);
	ArrayOfAttributesToExcludeWhenFillingIn.Add(Metadata.Documents.CashRegisterReceipt.TabularSections.Goods.Attributes.Sum.Name);
	
	While Selection.Next() Do
		LineReceiptCashRegisterProducts = CashRegisterReceiptGoods.Add();
		FillPropertyValues(LineReceiptCashRegisterProducts, Selection, , StrConcat(ArrayOfAttributesToExcludeWhenFillingIn, ","));
		
		LineReceiptCashRegisterProducts.Price 				= -Object.Goods[Selection.LineNumber-1].Price;
		
		LineReceiptCashRegisterProducts.NumberOfPackages 	= -Selection.NumberOfPackages;
		LineReceiptCashRegisterProducts.VATAmount 			= -Selection.VATAmount;
		LineReceiptCashRegisterProducts.Sum 				= -Selection.Sum;
	EndDo;
	
EndProcedure

&AtServer
Procedure CalculateIntroducedDiscrepancies()
	
	Discrepancies.Clear();
	
	DiscrepancyCalculationTable = CashRegisterReceiptGoods.Unload();
	
	For Each TSRow In Object.Goods Do
		RowOfDiscrepancyCalculationTable = DiscrepancyCalculationTable.Add();
		FillPropertyValues(RowOfDiscrepancyCalculationTable, TSRow);
		
		RowOfDiscrepancyCalculationTable.ProductsUnitOfMeasure = 
			Common.ObjectAttributeValue(TSRow.Products, "UnitOfMeasure");
	EndDo;
	
	GroupColumns = "LineNumber, Consignor, Products, ItemsType, Characteristic, ItemVariantsAreUsed, BatchesIndicationStatus, Series, Package, ProductsUnitOfMeasure, VATRate";
	TotalingColumns = "NumberOfPackages, Price, VATAmount, Sum";
	DiscrepancyCalculationTable.GroupBy(GroupColumns, TotalingColumns);
	DiscrepancyCalculationTable.Sort("LineNumber Asc, NumberOfPackages Desc, Price Desc, VATAmount Desc, Sum Desc");
	
	IterationNumber = 1;
	IterationCount = DiscrepancyCalculationTable.Count();
	While IterationCount >= IterationNumber Do
		RowOfDiscrepancyCalculationTable = DiscrepancyCalculationTable[IterationCount - IterationNumber];
		
		If RowOfDiscrepancyCalculationTable.NumberOfPackages = 0
			And RowOfDiscrepancyCalculationTable.VATAmount = 0
			And RowOfDiscrepancyCalculationTable.Sum = 0 Then
			
			DiscrepancyCalculationTable.Delete(RowOfDiscrepancyCalculationTable);
		EndIf;
		
		IterationNumber = IterationNumber + 1;
	EndDo;
	
	Discrepancies.Load(DiscrepancyCalculationTable);
	
	UpdateDiscrepancyPageTitle();
	
EndProcedure

&AtServer
Procedure UpdateDiscrepancyPageTitle()
	
	DiscrepanciesNumberOfRows = Discrepancies.Count();
	
	If DiscrepanciesNumberOfRows > 0 Then
		PHeader = StrTemplate(NStr("vi = 'Chênh lệch (%1)';
									|ru = 'Расхождения (%1)';
									|en = 'Discrepancies (%1)'; fa = 'Discrepancies (%1)';
									|it = 'Discrepanze (%1)';
									|pl = 'Odchylenie (%1)';
									|tr = 'Tutarsızlıklar (%1)'"), DiscrepanciesNumberOfRows);
	Else
		PHeader = NStr("vi = 'Chênh lệch';
						|ru = 'Расхождения';
						|en = 'Discrepancies'; fa = 'مغایرت‌ها';
						|it = 'Discrepanze';
						|pl = 'Odchylenie';
						|tr = 'Tutarsızlıklar'");
	EndIf;
	
	Items.DiscrepancyPage.Title = PHeader
	
EndProcedure

&AtServer
Function CashRegisterParameters()
	
	Return New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(Object.CashRegister));
	
EndFunction

&AtServer
Function FiscalOperationData()
	
	Return RetailSales.StructureOfFiscalTransactionData();
	
EndFunction

&AtServer
Function DetailsOfTheCashier()
	
	Return RetailSales.DetailsOfTheCashier(Users.CurrentUser(), Object.Organization);
	
EndFunction

&AtServer
Function AllowedToChangeProducts(Products)
	
	FlagAllowedToChangeProducts = True;
	
	
	Return FlagAllowedToChangeProducts;
	
EndFunction

&AtClient
Function ChangingProducts(ItemName)
	
	FlagChangingProducts = True;
	
	ArrayOfProductItems = New Array;
	ArrayOfProductItems.Add("GoodsProducts");
	ArrayOfProductItems.Add("GoodsCharacteristic");
	ArrayOfProductItems.Add("GoodsBatchesIndicationStatus");
	ArrayOfProductItems.Add("GoodsSeries");
	ArrayOfProductItems.Add("Consignor");
	
	If ArrayOfProductItems.Find(ItemName) = Undefined Then
		FlagChangingProducts = False;
	EndIf;
	
	Return FlagChangingProducts;
	
EndFunction

&AtClient
Procedure PostIssueReceipt()
	
	ClearMessages();
	
	If Object.Posted Then
		IssueCashReceipt();
	Else
		ProcessRecordingMode();
	EndIf;
	
EndProcedure

#Region PrintingReceipt

&AtServer
Function ParametersOfReceiptFiscalizationOperationOnServer()
	
	ParametersOfReceiptFiscalizationOperation = GeneratingFiscalCheckParametersServer
		.ParametersOfReceiptFiscalizationOperation(Object.Ref, Object.Organization);
	ParametersOfReceiptFiscalizationOperation.Insert("FDFVersion", FDFVersion);
	ParametersOfReceiptFiscalizationOperation.Insert("DeviceID", CashRegisterParameters.DeviceID);
	
	GeneratingFiscalCheckParametersServer.FiscalReceiptParametersAndPaymentType(
		ParametersOfReceiptFiscalizationOperation,
		Enums.CashSettlementTypes.CashReceipt);
		
	GeneratingFiscalCheckParametersServer.FiscalReceiptParametersAndEquipmentSerialNumber(
		ParametersOfReceiptFiscalizationOperation,
		CashRegisterParameters.SerialNumber);
		
	GeneratingFiscalCheckParametersServer.UpdateFiscalReceiptParametersSettlementLocation(
		ParametersOfReceiptFiscalizationOperation,
		Object.Organization,
		StructureRegisterShiftState.CashRegister,
		CashRegisterParameters.DeviceID);
	
	CorrectionData = New Structure();
	CorrectionData.Insert("AdjustmentType", Number(Object.AdjustmentType = Enums.TypesOfAdjustmentReceipts.ByPrescription));
	CorrectionData.Insert("AdjustmentDescription", Object.AdjustmentDescription);
	CorrectionData.Insert("CorrectionDate_", Object.DateOfAdjustedCalculation);
	CorrectionData.Insert("PrescriptionNumber", Object.PrescriptionNumberOfTaxAuthority);
	
	GeneratingFiscalCheckParametersServer.FiscalReceiptParametersFillInCorrectionParameters(
		ParametersOfReceiptFiscalizationOperation,
		?(Object.TypeOfCorrection = Enums.KindsOfAdjustmentReceipts.CorrectionOfErrors, Object.CashRegisterReceipt, Undefined),
		Object.TypeOfCorrection,
		CorrectionData
	);
	
	GeneratingFiscalCheckParametersServer.UpdateParametersOfFiscalReceiptAndCashRegisterReceipt(
		ParametersOfReceiptFiscalizationOperation,
		Object.Ref);
	
	GeneratingFiscalCheckParametersServer.UpdateFiscalReceiptParametersCashRegisterReceiptPaymentTable(
		ParametersOfReceiptFiscalizationOperation,
		PaymentInformation(ThisObject));
	
	GeneratingFiscalCheckParametersServer.FiscalReceiptParametersFillInParametersForSendingElectronicReceipt(
		ParametersOfReceiptFiscalizationOperation,
		Enums.OptionsOfSendingElectronicReceiptToCustomer.DontSend,
		"");
	
	Return ParametersOfReceiptFiscalizationOperation;
	
EndFunction

&AtClient
Function ParametersOfReceiptFiscalizationOperation()
	
	Return ParametersOfReceiptFiscalizationOperationOnServer();
	
EndFunction

&AtClientAtServerNoContext
Function PaymentInformation(Form)
	
	Form.DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Form.Object.Goods, Form.Object.PriceIncludesVAT);
	
	DiscountAmountBonusPoints = Form.Object.Goods.Total("AmountOfBonusPointsToDeductionInCurrency");
	
	PaymentInformation = New Structure;
	PaymentInformation.Insert("Document",              Form.Object.Ref);
	
	PaymentInformation.Insert("CashPayment",              Form.Object.ReceivedInCash);
	PaymentInformation.Insert("PaymentCards",        Form.Object.PaymentWithPaymentCards.Total("Sum"));
	PaymentInformation.Insert("GiftCertificates", Form.Object.GiftCertificates.Total("Sum"));
	PaymentInformation.Insert("BonusPoints",         DiscountAmountBonusPoints);
	
	Return PaymentInformation;
	
EndFunction

&AtClient
Procedure IssueCashReceipt()
	
	RetailSalesClient.ProcessShiftState(
		ThisObject,
		New CallbackDescription("PushReceiptProcessingNotifications", ThisObject));
	
EndProcedure

&AtClient
Procedure PunchReceiptAfterTransaction(ParametersOfReceiptFiscalizationOperation)
	
	CallbackDescription = New CallbackDescription("IssueCashReceiptCompletion", ThisObject);
	
	Result = EquipmentManagerTMClient.EquipmentAttached(CashRegisterParameters.DeviceID);
	
	If Result Or CashRegisterParameters.UseWithoutConnectingPeripherals Then
		
		If Not CashRegisterParameters.UseWithoutConnectingPeripherals Then
			
			CheckMarkingCodeByMeansOfKKT(ParametersOfReceiptFiscalizationOperation);
			
		Else
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("CallbackDescription", CallbackDescription);
			
			ExecutionResult = New Structure;
			ExecutionResult.Insert("Result", True);
			PrintingReceipt_Completion(
				ExecutionResult,
				AdditionalParameters);
			
		EndIf;
		
	Else
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Máy tính tiền không được kết nối. Phiếu tính tiền không được in.';
				|ru = 'Фискальное устройство не подключено. Чек не напечатан.';
				|en = 'Fiscal device is not connected. The receipt is not printed.'; fa = 'Fiscal device is not connected. The receipt is not printed.';
				|it = 'Dispositivo fiscale non collegato. Scontrino non stampato.';
				|pl = 'Urządzenie fiskalne nie jest podłączone. Paragon nie został wydrukowany.';
				|tr = 'Mali cihaz bağlı değil. Fiş yazdırılmamış.'"));
			
		RunCallback(
			CallbackDescription,
			New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded",
				False, False));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintingReceipt_AfterOpeningReceipt(ExecutionParameters, AdditionalParameters) Export
	
	RunCallback(ExecutionParameters.ContinueNotification, ExecutionParameters);
	
EndProcedure

&AtClient
Procedure PrintingReceipt_Completion(ExecutionResult, AdditionalParameters) Export
	
	ModifiedDataIsRecorded = False;
	OperationPerformedOnDevice = False;
	
	If ExecutionResult.Result Then
		
		Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_"); // The presence of an entry in the register is a sufficient sign, the props are not needed.
		If ExecutionResult.Property("KKTReceiptNumber") Then
			Object.CashRegisterReceiptNumber = Number(ExecutionResult.KKTReceiptNumber);
		EndIf;
		
		DataForEventLog = New Structure;
		DataForEventLog.Insert("Date",   Object.Date);
		DataForEventLog.Insert("Status", Object.Status);
		
		FiscalizationParameters = Undefined;
		If ExecutionResult.Property("OutputParametersSet")
			And ExecutionResult.OutputParametersSet.Count() > 1 Then
				
			DataForEventLog.Insert("CashRegisterReceiptNumber", ExecutionResult.OutputParametersSet[1]);
			Object.CashRegisterReceiptNumber = Number(DataForEventLog.CashRegisterReceiptNumber);
			
			// If the data was not recorded in the Fiscal Operation register, an error occurred during recording.
			If ExecutionResult.OutputParametersSet.Count() > 8 Then
				FiscalizationParameters = ExecutionResult.OutputParametersSet[8];
			EndIf;
		EndIf;
		
		OperationPerformedOnDevice = True;
		Modified = True;
		
		RetryRecordingIsRequired = False;
		ModifiedDataIsRecorded = RecordFiscalTransactionOnClient(RetryRecordingIsRequired, FiscalizationParameters);
		If Not ModifiedDataIsRecorded Then
			
			AdditionalParametersRepeatRecording = RetailSalesClientServer.RecordingRepeatStructure();
			AdditionalParametersRepeatRecording.DetailsOfCashNodeSFiscalOperation = FiscalizationParameters;
			AdditionalParametersRepeatRecording.CallbackDescription                       = AdditionalParameters.CallbackDescription;
			AdditionalParametersRepeatRecording.MessageText                 = NStr("vi = 'Sau khi lập phiếu tra trên FR, Chứng từ không thể được lưu.';
																					|ru = 'После пробития чека на ФР не удалось сохранить документ.';
																					|en = 'Cannot save the document after cash receipt has been issued in the fiscal register.'; fa = 'Cannot save the document after cash receipt has been issued in the fiscal register.';
																					|it = 'Dopo l''emissione dello scontrino dal registratore di cassa non è stato possibile salvare il documento.';
																					|pl = 'Po wydrukowaniu paragonu na rejestratorze fiskalnym nie udało się zapisać dokumentu.';
																					|tr = 'Bir fişi sayaca girdikten sonra belge kaydedilemedi.'");
			AdditionalParametersRepeatRecording.ReturnFunctionResult     = False;
			AdditionalParametersRepeatRecording.ResultOfSuccessfulImplementation = New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded", True, True);
			AdditionalParametersRepeatRecording.CancellationResult_             = New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded", True, False);
			AdditionalParametersRepeatRecording.ProcedureName                   = "RecordFiscalTransactionOnServer";
			AdditionalParametersRepeatRecording.OperationResult              = ModifiedDataIsRecorded;
			
			ShowQueryBox(
				New CallbackDescription("ErrorDuringReceiptIssueCompletion", ThisObject, AdditionalParametersRepeatRecording),
				AdditionalParametersRepeatRecording.MessageText,
				QuestionDialogMode.RetryCancel, 10, DialogReturnCode.Retry,,DialogReturnCode.Retry);
			Return;
			
		EndIf;
		
		If Object.TypeOfCorrection = PredefinedValue("Enum.KindsOfAdjustmentReceipts.CRENonApplication") Then
			ArchivePendingCashRegisterReceipt(Object.CashRegisterReceipt);
		EndIf;
		
	Else
		
		MessageText = NStr("vi = 'Khi in phiếu điều chỉnh đã xảy ra lỗi.
		                            |Phiếu chưa được in trên máy tính tiền.
		                            |Mô tả bổ sung:
		                            |%AdditionalDetails%';
		                            |ru = 'При печати чека коррекции произошла ошибка.
		                            |Чек не напечатан на фискальном устройстве.
		                            |Дополнительное описание:
		                            |%AdditionalDetails%';
		                            |en = 'An error occurred when printing an adjustment voucher. 
		                            | The voucher is not printed on a fiscal device. 
		                            |Additional description:
		                            | %AdditionalDetails%'; fa = 'An error occurred when printing an adjustment voucher. 
		                            | The voucher is not printed on a fiscal device. 
		                            |Additional description:
		                            | %AdditionalDetails%';
		                            |it = 'Durante la stampa dello scontrino di correzione si è verificato un errore.
		                            |Scontrino non è stato stampato dal dispositivo fiscale.
		                            |Descrizione aggiuntiva:
		                            | %AdditionalDetails%';
		                            |pl = 'Podczas drukowania paragonu korekty wystąpił błąd.
		                            |Paragon nie jest wydrukowany na urządzeniu fiskalnym.
		                            |Dodatkowy opis:
		                            |%AdditionalDetails%';
		                            |tr = 'Fiş yazdırılırken hata oluştu.
		                            |Fiş mali cihazda yazdırılamadı.
		                            |Ek açıklama: 
		                            |%AdditionalDetails%.'");
		
		MessageText = StrReplace(
			MessageText,
			"%AdditionalDetails%",
			ExecutionResult.ErrorDescription);
		CommonClientServer.MessageToUser(MessageText);
		
		// Close the KM check session on the CCT if it was opened
		RetailSalesClient.CloseKmVerificationSessionOnCCT(ThisObject.UUID, CashRegisterParameters.DeviceID);
		
	EndIf;
	
	RunCallback(
		AdditionalParameters.CallbackDescription,
		New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded",
			OperationPerformedOnDevice, ModifiedDataIsRecorded));		
	
EndProcedure

&AtClient
Procedure IssueCashReceiptCompletion(Result, AdditionalParameters) Export
	
	If Result.OperationPerformedOnDevice Then
		
		ReadOnly = True;
		SetVisibilityOfButtonFiscalizationOfCorrectionReceipt();
		
		Notify("Write_ReceiptOfCashRegisterAdjustment", New Structure, Undefined);		
		
		If Not Result.ModifiedDataIsRecorded Then
			
			FormParameters = New Structure;
			FormParameters.Insert("Data", Object.Ref);
			FormParameters.Insert("DataForEventLog", DataForEventLog);
			FormParameters.Insert("MessageText",
				NStr("vi = 'CHÚ Ý! Đã xảy ra tình huống đặc biệt:
				|Đã đánh phiếu tính tiền điều chỉnh, nhưng chưa ghi nhận trong hệ thống.';
				|ru = 'ВНИМАНИЕ! Произошла исключительная ситуация:
				|Чек ККМ коррекции пробит, но не зафиксирован в системе.';
				|en = 'ATTENTION! An exception occurred:
				| Cash register adjustment voucher is issued but not recorded in the system.'; fa = 'ATTENTION! An exception occurred:
				| Cash register adjustment voucher is issued but not recorded in the system.';
				|it = 'ATTENZIONE! si è verificata una situazione eccezionale:
				|lo Scontrino del registratore di cassa di correzione è stato emesso, ma non è stato registrato nel sistema.';
				|pl = 'UWAGA! Wystąpiła wyjątkowa sytuacja:
				|Paragon kasy korekty został skasowany, ale nie jest zarejestrowany w systemie.';
				|tr = 'UYARI! İstisnai bir durum meydana geldi:
				|Kasa düzeltme fişi kesilmiş ancak sisteme kaydedilmemiştir.'"));
			
			OpenForm("Document.ReceiptOfCashRegisterAdjustment.Form.WritingError", FormParameters, ThisObject);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FiscalTransaction

&AtServer
Procedure FiscalOperationUpdateStatus()
	
	If ValueIsFilled(Object.Ref) Then
		FiscalOperationLogData = EquipmentReceiptPrintersServerCall.ListOfFiscalTransactions(Object.Ref);
	Else
		FiscalOperationLogData = Undefined;
	EndIf;
	
	Rows = New Array;
	If FiscalOperationLogData = Undefined
		Or (TypeOf(FiscalOperationLogData) = Type("Array") And FiscalOperationLogData.Count() = 0) Then
		
		Rows.Add("");
		
	Else
		
		ListOfRooms = New ValueList();
		For Each FiscalTransaction In FiscalOperationLogData Do
			ListOfRooms.Add(FiscalTransaction.CashRegisterReceiptNumber);
		EndDo;
		ListOfRooms.SortByValue(SortDirection.Asc);
		
		For Each ReceiptNumber In ListOfRooms Do
			
			RecordID = "";
			For Each FiscalTransaction In FiscalOperationLogData Do
				If FiscalTransaction.CashRegisterReceiptNumber = ReceiptNumber.Value Then
					RecordID = FiscalTransaction.RecordID;
					Break;
				EndIf;
			EndDo;
			
			If Rows.Count() Then
				Rows.Add(" ");	
			EndIf;	
			
			Rows.Add(
				New FormattedString(
					StrTemplate(
						NStr("vi = 'Đã đánh phiếu số%1';
							|ru = 'Пробит чек №%1';
							|en = 'Receipt No.%1 is issued'; fa = 'Receipt No.%1 is issued';
							|it = 'Scontrino №%1 emesso';
							|pl = 'Wydrukowano paragon nr%1';
							|tr = 'Fiş No%1 kesildi'"),
						ReceiptNumber.Value),,
					StyleColors.HyperlinkColor,,
					"OpenRecordOfFiscalTransaction" + RecordID));
					
			Rows.Add(NStr("vi = ' và';
							|ru = ' и';
							|en = ' and'; fa = ' and';
							|it = ' e';
							|pl = ' i';
							|tr = 've'"));
		EndDo;
		
		Rows.Delete(Rows.Count() -1 );
		
	EndIf;
	
	FiscalOperationStatus = New FormattedString(Rows);
	
EndProcedure

&AtClient
Procedure FiscalOperationNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If StrFind(FormattedStringURL, "OpenRecordOfFiscalTransaction") Then
		RecordID = Mid(FormattedStringURL, 32);
		TMPeripheralsClient.OpenRecordOfFiscalTransaction(ThisObject, Object.Ref, RecordID);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure RecalculateDocumentOnClient()
	
	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Object.Goods, Object.PriceIncludesVAT);
	PaidOther = Object.PaymentWithPaymentCards.Total("Sum") + Object.GiftCertificates.Total("Sum");
	ChangeAmount = Object.PaymentWithPaymentCards.Total("Sum") + Object.GiftCertificates.Total("Sum") + Object.ReceivedInCash - Object.DocumentAmount;
	
EndProcedure

&AtServer
Procedure SetPresentationOfFoundationDocument()
	
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		BaseDocumentPresentation = String(Object.CashRegisterReceipt);
		Items.BaseDocumentPresentation.TextColor = StyleColors.HyperlinkColor;
	EndIf;
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products_2", ParametersForFillingInBankingDetails);

	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ParametersForFillingInBankingDetails);
	
	SetsServer.FillInServiceDetails(ThisForm);
	
EndProcedure

&AtServer
Procedure AdjustTypeOfCorrection()

	// Setting up the field display on the form
	FiscalTransaction = EquipmentReceiptPrintersServerCall.FiscalOperationData(Object.CashRegisterReceipt);

	Items.TypeOfCorrection.ChoiceList.Add(Enums.KindsOfAdjustmentReceipts.CorrectionOfErrors);
	Items.TypeOfCorrection.ChoiceList.Add(Enums.KindsOfAdjustmentReceipts.CRENonApplication);
	Items.TypeOfCorrection.ChoiceList.Add(Enums.KindsOfAdjustmentReceipts.SlipLockInFDO);
	
	If FiscalTransaction = Undefined Then
		Items.TypeOfCorrection.Enabled = False;
	Else
		Items.TypeOfCorrection.ChoiceList.Clear();
		Items.TypeOfCorrection.ChoiceList.Add(Enums.KindsOfAdjustmentReceipts.CorrectionOfErrors);
		Items.TypeOfCorrection.ChoiceList.Add(Enums.KindsOfAdjustmentReceipts.SlipLockInFDO);
	EndIf;

	// Setting the default value
	If Not ValueIsFilled(Object.TypeOfCorrection) Then
		Object.TypeOfCorrection = Enums.KindsOfAdjustmentReceipts.CorrectionOfErrors;
		If FiscalTransaction = Undefined Then
			Object.TypeOfCorrection = Enums.KindsOfAdjustmentReceipts.CRENonApplication;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Function CalculatePrice(Sum, Count, VATAmount, PriceIncludesVAT)

	If PriceIncludesVAT Then
		Price = Sum / Count;
	EndIf;

	If Not PriceIncludesVAT Then
		Price = (Sum - VATAmount) / Count;
	EndIf;
	
	Return Price;

EndFunction

&AtServer
Procedure SetValuesBySettings()
	
	CashRegisterParameters = CashRegisterParameters();
	FDFVersion = EquipmentManagerServerCall.FiscalDeviceSupportsFFDVersion(CashRegisterParameters.DeviceID);
	StructureRegisterShiftState = RetailSales.GetCashShiftState(Object.CashRegister);
	
	If ValueIsFilled(Object.Ref) Then
		
		If Object.Status <> Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_
			And Object.CashRegisterShift <> StructureRegisterShiftState.CashRegisterShift Then
			Object.CashRegisterShift = StructureRegisterShiftState.CashRegisterShift;
		EndIf;
		
		CurrentUser = Users.CurrentUser();
		If Object.Status <> Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_
			And Object.Cashier <> CurrentUser Then
			Object.Cashier = CurrentUser;
		EndIf;
		
		
	EndIf;
	
	AccessRights = New Structure;
	AccessRights.Insert("OpenShift", AccessRight("Update", Metadata.Documents.CashRegisterShift));
	AccessRights.Insert("CloseShift", AccessRight("Update", Metadata.Documents.CashRegisterShift));
	
EndProcedure

&AtClient
Procedure BeforeClosingReceipt(Cancel, CallbackDescription = Undefined)
	
	// Close the KM check session on the CCT if it was opened
	RetailSalesClient.CloseKmVerificationSessionOnCCT(ThisObject.UUID, CashRegisterParameters.DeviceID);
	
EndProcedure

&AtServer
Procedure ArchivePendingCashRegisterReceipt(CashRegisterReceipt)
	
	CashRegisterReceiptObject = Object.CashRegisterReceipt.GetObject();
	CashRegisterReceiptObject.Archived      = False;
	CashRegisterReceiptObject.CashRegisterShift = Object.CashRegisterShift;
	CashRegisterReceiptObject.Status        = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_");
	CashRegisterReceiptObject.CashRegisterReceiptNumber  = Object.CashRegisterReceiptNumber;
	CashRegisterReceiptObject.Write(DocumentWriteMode.Posting);
	
EndProcedure

#Region Localization

&AtClient
Procedure ConductFormatAndLogicalControlLocalization(ParametersOfReceiptFiscalizationOperation, DeviceID)
	
	
EndProcedure

&AtClient
Procedure GoodsConsignorOnChangeLocalization(Item)


EndProcedure

#EndRegion

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
