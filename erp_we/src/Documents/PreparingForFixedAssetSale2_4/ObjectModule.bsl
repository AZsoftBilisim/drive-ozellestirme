#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocument();
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.Assets") Then
		FillInBasedOnObjectOfOperation(FillingData);
	EndIf;
	
	PreparingForFixedAssetSaleLocalization.Filling(ThisObject, FillingData, StandardProcessing);

	FillParameters = Documents.PreparingForFixedAssetSale2_4.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	Actions = New Structure();
	Actions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
	BatchProcessingOfTablePartServer.TreatTS(FA, Actions, Undefined);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");
	
	PreparingForFixedAssetSaleLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
	NonCurrentAssetsInternal.CheckThatFAHasNotBeenTransferredToFinLease(ThisObject, Cancel);
	NonCurrentAssetsInternal.CheckThatFAHaveBeenSelected(ThisObject, "FA", "FixedAsset", Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	PreparingForFixedAssetSaleLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		NonCurrentAssetsInternal.CheckThatFAIsTakenIntoAccount(ThisObject, Cancel);
		
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");
	
	PreparingForFixedAssetSaleLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	PreparingForFixedAssetSaleLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	PreparingForFixedAssetSaleLocalization.Posting(ThisObject, Cancel, PostingMode);
	
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	PreparingForFixedAssetSaleLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	PostInAccounting = True;
	RecordInTA = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	Date = BegOfDay(CurrentSessionDate());
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	FillParameters = Documents.PreparingForFixedAssetSale2_4.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions.Insert("AdjustVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
	BatchProcessingOfTablePartServer.TreatTS(FA, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		FA,
		CachedValues);
	
EndProcedure

Procedure FillInSelectionDocument(Basis)

	If Basis.Property("FixedAsset") Then
		FillInBasedOnObjectOfOperation(Basis.FixedAsset);
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnObjectOfOperation(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	If Common.ObjectAttributeValue(Basis, "IsFolder") Then
		
		MessageText = NStr("vi = 'Không thể chuẩn bị chuyển giao nhóm TSCĐ.
			|Hãy chọn TSCĐ. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên đi xuống.';
			|ru = 'Подготовка к передаче группы ОС невозможна.
			|Выберите ОС. Для раскрытия группы используйте клавиши Ctrl и стрелку вниз.';
			|en = 'Cannot prepare fixed assets group for handover.
			|Select fixed assets. To expand the group, press Ctrl+Down.'; fa = 'Cannot prepare fixed assets group for handover.
			|Select fixed assets. To expand the group, press Ctrl+Down.';
			|it = 'Preparazione al trasferimento del gruppo Capitale Fisso non è possibile.
			|Selezionate il capitale fisso. Per aprire il gruppo utilizzate i tasti Ctrl e la freccia giù.';
			|pl = 'Przygotowanie do biegu grupy ST nie jest możliwe. 
			|Wybierz ST. Aby rozwinąć grupę, użyj klawisza Ctrl i strzałkę w dół.';
			|tr = 'Sabit kıymet gruplarına aktarım için hazırlamak mümkün değildir.
			| Sabit kıymet seçin. Grubu genişletmek için Ctrl tuşunu ve aşağı oku kullanın.'");
		Raise(MessageText);
		
	EndIf;
	
	InitialInformation = Catalogs.Assets.InitialInformation(Basis, Date);

	FALocation = NonCurrentAssets.FALocation(Basis);
	FillPropertyValues(ThisObject, FALocation);
	Department = FALocation.FixedAssetsLocation;
	
	LineOfATabularSection = FA.Add();
	LineOfATabularSection.FixedAsset = Basis;
	
	RecordInManAccounting = ValueIsFilled(InitialInformation.CommissioningDocumentMA);
	PostInAccounting = ValueIsFilled(InitialInformation.CommissioningDocumentAC);
	RecordInTA = ValueIsFilled(InitialInformation.CommissioningDocumentTA);
	RecordInLocalAccounting = PostInAccounting Or RecordInTA;
	
	Documents.PreparingForFixedAssetSale2_4.FillInExpenseItemRetirement(Organization, Date, FA, RetirementItem);
	
EndProcedure

#EndRegion

#EndIf
