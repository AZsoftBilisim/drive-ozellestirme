#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing) Export
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		If Not FillingData.Property("ReadingFormCommands") Then
			FillInSelectionDocument(FillingData);
		EndIf;
		
	ElsIf FillInDataType = Type("DocumentRef.CashRegisterReceipt") Then
		
		FillOutDocumentOnCashRegisterReceipt(FillingData);
		
	Else
		
		If Catalogs.CashRegisters.CashRegisterOfKKMIsCreatedInSystem() Then
			
			CashRegister = Catalogs.CashRegisters.CashRegisterCashRegisterFiscalRegistrarForCWP();
			If ValueIsFilled(CashRegister) Then
				FillInDocumentAtCashRegister(CashRegister);
			Else
				Raise NStr("vi = 'Người sử dụng không đủ quyền truy cập đến thiết bị kết nối: Máy ghi nhận tiền mặt';
							|ru = 'У пользователя недостаточно прав на подключаемое оборудование: Фискальный регистратор';
							|en = 'The user has insufficient access rights for the peripherals: Fiscal cash register'; fa = 'The user has insufficient access rights for the peripherals: Fiscal cash register';
							|it = 'У пользователя недостаточно прав на подключаемое оборудование: Фискальный регистратор';
							|pl = 'The user has insufficient access rights for the peripherals: Fiscal cash register';
							|tr = 'Kullanıcının bağlı donanım üzerinde yeterli hakkı yok: Mali kayıt memuru'");
			EndIf;  
			
		Else
			
			Raise NStr("vi = 'Để tiếp tục làm việc trong quầy thu ngân, cần tạo ít nhất một quầy thu ngân';
						|ru = 'Для продолжения работы в РМК необходимо создать хотя бы одну кассу ККМ';
						|en = 'To use the point of sale workplace, create at least one cash register'; fa = 'To use the point of sale workplace, create at least one cash register';
						|it = 'Для продолжения работы в РМК необходимо создать хотя бы одну кассу ККМ';
						|pl = 'To use the point of sale workplace, create at least one cash register';
						|tr = 'Kasiyerin İş Yeri''nde çalışabilmeye devam etmek için en az bir Yazar Kasa Cihazı kasası oluşturulmalıdır'");
		EndIf;
		
	EndIf;
	
	InitializeDocument(FillingData);
	
	CashRegisterReceiptLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Status) Then
		Status = Enums.CashRegisterReceiptStatuses.DeferredWithoutReservation;
	EndIf;
	
	If Status = Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_ Then
		
		If WriteMode = DocumentWriteMode.Posting Then
			
			FillInCalculationObject();
			
		ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
			
			Cancel = True;
		
			ErrorText = NStr("vi = 'Phiếu tính tiền đã đánh. Không thể hủy bỏ kết chuyển';
							|ru = 'Чек ККМ пробит. Отмена проведения невозможна';
							|en = 'Receipt is issued. Posting cancellation is unavailable'; fa = 'Receipt is issued. Posting cancellation is unavailable';
							|it = 'Scontrino del registratore di cassa è stato emesso. Cancellazione impossibile';
							|pl = 'Wydrukowano paragon fiskalny. Anulowanie jest niemożliwe';
							|tr = 'Kasa fişi kesilmiştir. İptal mümkün değildir'");
			Common.MessageToUser(ErrorText, ThisObject);
			
			Return;
			
		EndIf;
	
	Else
		
		For Each TSRow In GiftCertificates Do
			TSRow.ARAPObject = Undefined;
		EndDo;
		
	EndIf;
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	GiftCertificatesServer.FillInAmountInCertificateCurrencyInTablePart(GiftCertificates, Organization, Date, Currency);
	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Goods, PriceIncludesVAT);
	
	ProductsServer.ClearUnusedSeries(ThisObject, ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.CashRegisterReceipt));
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,GiftCertificates,PaymentWithPaymentCards");
	
	If GetFunctionalOption("UseLoyaltyServerDataProvider")
		And GetFunctionalOption("UseLoyaltyPrograms")
		And Common.ObjectAttributeValue(CashRegister, "CashRegisterType") = Enums.CashRegisterTypes.StandaloneCWP Then
		AdditionalProperties.Insert("AdjustInformationRegisterBonusPointsForDebiting");
	EndIf;
	
	CashRegisterReceiptLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	If AdditionalProperties.Property("AdjustInformationRegisterBonusPointsForDebiting") Then
		LoyaltyService.AdjustInformationRegisterBonusPointsForDebiting(ThisObject);
	EndIf;
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Archived = False;
	Status = Undefined;
	
	ReceivedInCash = 0;
	PaymentWithPaymentCards.Clear();
	SetOfSeries.Clear();
	
	RegisterShiftState = RetailSales.GetCashShiftState(CashRegister);
	FillPropertyValues(ThisObject, RegisterShiftState);
	
	DiscountsAreCalculated = False;
	DiscountsMarkupsFillingServer.CancelDiscounts(ThisObject, "Goods", False);
	
	For Each TSRow In Goods Do
		TSRow.AmountOfBonusPointsToDeduction = 0;
		TSRow.AmountOfBonusPointsToDeductionInCurrency = 0;
	EndDo;
	
	InitializeDocument();
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions.Insert("AdjustVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Goods,
		CachedValues);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,GiftCertificates,PaymentWithPaymentCards");
	
	CashRegisterReceiptLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	If Not WarehousesServer.UseWarerooms(Warehouse,Date) Then
		NotCheckedAttributeArray.Add("Goods.Premise");
	EndIf;
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.CashRegisterReceipt),
												Cancel,
												NotCheckedAttributeArray);
	GiftCertificatesServer.FillCheckProcessing(ThisObject, Cancel);
	SalesServer.CheckCorrectnessOfSalesDocument(ThisObject, Cancel);
	RetailSales.CheckPaymentCompletionWithPaymentCards(ThisObject, Cancel);
	
	CashRegisterReceiptLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	Cashier = Users.CurrentUser();
	
	FillParameters = Documents.CashRegisterReceipt.ParametersForFillingInSalesVATTaxation(ThisObject);	
	If Not ValueIsFilled(FillParameters.Date) Then
		FillParameters.Date = CurrentSessionDate();
	EndIf;
	If ValueIsFilled(Department) Then
		FillParameters.Department = Department;
	EndIf;
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
EndProcedure

Procedure FillInDocumentAtCashRegister(CashRegister)
	
	RegisterShiftState = RetailSales.GetCashShiftState(CashRegister);
	FillPropertyValues(ThisObject, RegisterShiftState,,"Cashier");
	
EndProcedure

Procedure FillInSelectionDocument(FillingData)
	
	If FillingData.Property("CashRegister") Then
		FillInDocumentAtCashRegister(FillingData.CashRegister);
	EndIf;
	
EndProcedure

Procedure FillOutDocumentOnCashRegisterReceipt(CashRegisterReceiptRef)
	
	Query = New Query(
	"SELECT
	|	CashRegisterReceipt.CashRegister AS CashRegister,
	|	CashRegisterReceipt.Goods   AS Goods
	|FROM
	|	Document.CashRegisterReceipt AS CashRegisterReceipt
	|WHERE
	|	CashRegisterReceipt.Ref = &Ref");
	
	Query.SetParameter("Ref", CashRegisterReceiptRef);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		FillInDocumentAtCashRegister(Selection.CashRegister);
		Goods.Load(Selection.Goods.Unload());
	EndIf;
	
	OnCopy(CashRegisterReceiptRef);
	
EndProcedure

Procedure FillInCalculationObject()
	
	If GiftCertificates.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GiftCertificates.LineNumber AS LineNumber,
	|	CAST(GiftCertificates.GiftCertificate AS Catalog.GiftCertificates) AS GiftCertificate
	|INTO GiftCertificates
	|FROM
	|	&GiftCertificates AS GiftCertificates
	|INDEX BY
	|	GiftCertificate
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GiftCertificates.LineNumber AS LineNumber,
	|	GiftCertificates.GiftCertificate AS GiftCertificate,
	|	ARAPObjects.Ref AS ARAPObject
	|FROM
	|	GiftCertificates AS GiftCertificates
	|	LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON ARAPObjects.Object = GiftCertificates.GiftCertificate
	|			AND NOT ARAPObjects.DeletionMark
	|WHERE
	|	GiftCertificates.GiftCertificate.Owner.GiftCardAccounting25";
	
	Query.SetParameter("GiftCertificates", GiftCertificates.Unload());
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		IndexOf = Selection.LineNumber - 1;
		GiftCertificates[IndexOf].ARAPObject = Selection.ARAPObject;
		GiftCertificates[IndexOf].AmountARAP = GiftCertificates[IndexOf].Sum;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
