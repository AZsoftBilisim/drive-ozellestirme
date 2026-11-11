#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.IntangibleAssets") Then
		FillInBasedOnIA(FillingData);
	EndIf;
	
	InitializeDocument();
	
	PreparingForIntangibleAssetSaleLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "IA");
	
	PreparingForIntangibleAssetSaleLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NonCurrentAssets.CheckIfDateMatchesAccountingVersion(ThisObject, True, Cancel);
	
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "IA", "IntangibleAsset", Cancel);
	
	PreparingForIntangibleAssetSaleLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If WriteMode = DocumentWriteMode.Posting Then
		NonCurrentAssetsInternal.CheckThatIAAreAcceptedForAccounting(ThisObject, Cancel);
		NonCurrentAssetsInternal.FillInReflectionInAccounting(ThisObject, IA.Unload().UnloadColumn("IntangibleAsset"));
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "IA");
	
	PreparingForIntangibleAssetSaleLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	PreparingForIntangibleAssetSaleLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	PreparingForIntangibleAssetSaleLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	PreparingForIntangibleAssetSaleLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	
	RecordInManAccounting = True;
	RecordInLocalAccounting = True;
	
EndProcedure

Procedure FillInSelectionDocument(Basis)

	If Basis.Property("IntangibleAsset") Then
		FillInBasedOnIA(Basis.IntangibleAsset);
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnIA(Basis)
	
	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	DetailsOfFoundation = Common.ObjectAttributesValues(Basis, "IsFolder");
	
	If DetailsOfFoundation.IsFolder Then
		
		MessageText = NStr("vi = 'Không thể chuẩn bị chuyển giao nhóm TSCĐ vô hình.
			|Hãy chọn TSCĐ vô hình. Để mở nhóm, hãy sử dụng phím Ctrl và mũi tên đi xuống.';
			|ru = 'Подготовка к передаче группы НМА невозможна.
			|Выберите НМА. Для раскрытия группы используйте клавиши Ctrl и стрелку вниз.';
			|en = 'Cannot prepare intangible assets group for handover.
			|Select intangible assets. To expand the group, press Ctrl+Down.'; fa = 'Cannot prepare intangible assets group for handover.
			|Select intangible assets. To expand the group, press Ctrl+Down.';
			|it = 'Preparazione al trasferimento del gruppo Beni Immateriali non è possibile.
			|Selezionate il bene immateriale. Per aprire il gruppo utilizzate i tasti Ctrl e la freccia giù.';
			|pl = 'Przygotowanie do biegu grupy WNM jest niemożliwa. 
			|Wybierz WNM. Aby rozwinąć grupę, użyj klawisza Ctrl i strzałkę w dół.';
			|tr = 'Maddi olmayan varlık grubunu aktarım için hazırlamak mümkün değildir.
			| Maddi olmayan varlık seçin. Grubu genişletmek için Ctrl tuşunu ve aşağı oku kullanın.'");
		Raise(MessageText);
		
	EndIf;
	
	IntangibleAssetsRegistrationPlace = NonCurrentAssets.IntangibleAssetsRegistrationPlace(Basis);
	FillPropertyValues(ThisObject, IntangibleAssetsRegistrationPlace);
	
	LineOfATabularSection = IA.Add();
	LineOfATabularSection.IntangibleAsset = Basis;
	
EndProcedure

#EndRegion

#EndIf
