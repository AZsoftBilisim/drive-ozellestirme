#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	InitializeDocument();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	CheckAnalyticsOfArticle(CheckedAttributes, ExpenseItem, "DimensionOfExpenses");
	CheckAnalyticsOfArticle(CheckedAttributes, IncomeItem,  "DimensionOfRevenue");
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Date <> EndOfMonth(Date) Then
		Date = EndOfMonth(Date);
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	CheckVNAForEntryIntoCGU(Cancel, WriteMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	CheckRelevanceOfImpairment(Cancel);
	 
	If Not Cancel Then
		
		DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);

		CreateTaskForEndOfMonth();
		
	EndIf;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	CreateTaskForEndOfMonth();
	
EndProcedure

#EndRegion

#Region Private

// Check the VNA for entry into the EGDS.
// VNA included in the EGDS cannot be devalued separately from the EGDS.
// 
// Parameters:
//  Cancel - Boolean - Cancel
//  WriteMode - DocumentWriteMode - Recording mode
Procedure CheckVNAForEntryIntoCGU(Cancel, WriteMode)
	
	If WriteMode = DocumentWriteMode.UndoPosting Then
		Return;
	EndIf;
	
	FATable  = FixedAssets.Unload(,"FixedAsset,LineNumber");
	TableOfIA = IntangibleAssets.Unload(,"IntangibleAsset,LineNumber");
	
	Query = New Query;
	
	Query.Text =
		"SELECT
		|	FA.FixedAsset AS NonCurrentAsset,
		|	FA.LineNumber      AS LineNumber
		|INTO WTO
		|FROM
		|	&FATable AS FA
		|
		|INDEX BY
		|	NonCurrentAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	IA.IntangibleAsset AS NonCurrentAsset,
		|	IA.LineNumber         AS LineNumber
		|INTO VTNMA
		|FROM
		|	&TableOfIA AS IA
		|
		|INDEX BY
		|	NonCurrentAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	WTO.NonCurrentAsset AS NonCurrentAsset,
		|	WTO.LineNumber       AS LineNumber
		|INTO VNAWithoutCGU
		|FROM
		|	WTO AS WTO
		|
		|UNION ALL
		|
		|SELECT
		|	VTNMA.NonCurrentAsset AS NonCurrentAsset,
		|	VTNMA.LineNumber       AS LineNumber
		|FROM
		|	VTNMA AS VTNMA
		|
		|INDEX BY
		|	NonCurrentAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CGUCompositionSliceLast.NonCurrentAsset AS NonCurrentAsset,
		|	CGUCompositionSliceLast.CGU AS CGU,
		|	CGUCompositionSliceLast.Period AS Date,
		|	VNAWithoutCGU.LineNumber AS LineNumber,
		|	CASE
		|		WHEN CGUCompositionSliceLast.NonCurrentAsset REFS Catalog.Assets
		|			THEN &TCHOSName
		|		WHEN CGUCompositionSliceLast.NonCurrentAsset REFS Catalog.IntangibleAssets
		|			THEN &NameTCHNMA
		|	END AS TSName
		|FROM
		|	InformationRegister.CGUComposition.SliceLast(&DocumentBorder, Organization = &Organization
		|	AND NonCurrentAsset IN
		|		(SELECT
		|			VNAWithoutCGU.NonCurrentAsset
		|		FROM
		|			VNAWithoutCGU AS VNAWithoutCGU)) AS CGUCompositionSliceLast
		|		LEFT JOIN VNAWithoutCGU AS VNAWithoutCGU
		|		ON CGUCompositionSliceLast.NonCurrentAsset = VNAWithoutCGU.NonCurrentAsset
		|WHERE
		|	CGUCompositionSliceLast.CGU <> VALUE(Catalog.CashGeneratingUnits.EmptyRef)
		|
		|ORDER BY
		|	TSName DESC,
		|	LineNumber";
		
	Query.SetParameter("DocumentBorder", New Boundary(Date, BoundaryType.Including));
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("FATable",  FATable);
	Query.SetParameter("TableOfIA", TableOfIA);
	
	Query.SetParameter("TCHOSName" , NStr("vi = 'Tài sản cố định hữu hình';
											|ru = 'Основные средства';
											|en = 'Fixed assets'; fa = 'دارایی‌های ثابت';
											|it = 'Capitali fissi';
											|pl = 'Środki trwałe';
											|tr = 'Sabit kıymetler'"));
	Query.SetParameter("NameTCHNMA", NStr("vi = 'Tài sản cố định vô hình';
											|ru = 'Нематериальные активы';
											|en = 'Intangible assets'; fa = 'دارایی‌های نامشهود';
											|it = 'Beni immateriali';
											|pl = 'Wartości niematerialne';
											|tr = 'Maddi olmayan varlıklar'"));
	
	CheckResult = Query.Execute();
	
	If CheckResult.IsEmpty() Then
		Return;
	EndIf;
	
	// The VNA included in the EGDS, and mentioned in the tabular parts of the independent VNA, were found.
	Common.MessageToUser(
				NStr("vi = 'Đã tìm thấy tài sản dài hạn thuộc thành phần đơn vị tạo tiền.';
					|ru = 'Обнаружены внеоборотные активы, входящие в состав ЕГДС.';
					|en = 'Fixed and intangible assets included in the cash-generating unit are found.'; fa = 'Fixed and intangible assets included in the cash-generating unit are found.';
					|it = 'Sono stati rilevati attivi non correnti facenti parte dell''unità generatrice di cassa.';
					|pl = 'Wykryto aktywa nieobrotowe, wchodzące do zestawu jednostki generującej środki pieniężne.';
					|tr = 'Nakit yaratan birime dahil olan duran varlıklar belirlenmiştir.'"),
				Ref,
				,
				,
				Cancel);
	Cancel = True;
	
	ErrorTextTemplate = NStr("vi = '%1, dòng %2: %3 thuộc thành phần đơn vị tạo tiền %4 có %5.';
							|ru = '%1, строка %2: %3 входит в состав ЕГДС %4 с %5.';
							|en = '%1, line %2: %3 included in the cash-generating unit %4 from %5.'; fa = '%1, line %2: %3 included in the cash-generating unit %4 from %5.';
							|it = '%1 riga %2: %3 incluso nell''unità generatrice di cassa %4 da %5.';
							|pl = '%1, wiersz %2: %3 wchodzi do zestawu jednostki generującej środki pieniężne %4 z %5.';
							|tr = '%1, satır %2: %3, %5 ile %4 NYB''nin bir parçasıdır.'");
	
	VNAFromCGU = CheckResult.Select();
	
	While VNAFromCGU.Next() Do
		
		ErrorText = StrTemplate(ErrorTextTemplate,
									VNAFromCGU.TSName,
									VNAFromCGU.LineNumber,
									VNAFromCGU.NonCurrentAsset,
									VNAFromCGU.CGU,
									Format(VNAFromCGU.Date,"DLF=D;"));
		
		Common.MessageToUser(
				ErrorText,
				Ref,
				,
				,
				Cancel);

	EndDo;
	
EndProcedure


Procedure InitializeDocument()
	
	Date = EndOfMonth(CurrentSessionDate());
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
EndProcedure

Procedure CheckRelevanceOfImpairment(Cancel)
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	ImpairmentOfVNAPre.Ref AS ImpairmentDocument,
		|	ImpairmentOfVNAPre.CGU AS NCA,
		|	""CashGeneratingUnits"" AS TS
		|FROM
		|	Document.ImpairmentFA.CashGeneratingUnits AS ImpairmentOfVNAPre
		|		INNER JOIN Document.ImpairmentFA.CashGeneratingUnits AS ImpairmentOfVNACur
		|		ON (ImpairmentOfVNACur.CGU = ImpairmentOfVNAPre.CGU)
		|WHERE
		|	ImpairmentOfVNAPre.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND ImpairmentOfVNAPre.Ref.Organization = &Organization
		|	AND ImpairmentOfVNAPre.Ref.Posted
		|	AND ImpairmentOfVNAPre.Ref <> &CurrentDocument
		|	AND ImpairmentOfVNACur.Ref = &CurrentDocument
		|
		|GROUP BY
		|	ImpairmentOfVNAPre.Ref,
		|	ImpairmentOfVNAPre.CGU
		|
		|UNION ALL
		|
		|SELECT
		|	ImpairmentOfVNAPre.Ref,
		|	ImpairmentOfVNAPre.FixedAsset,
		|	""FixedAssets""
		|FROM
		|	Document.ImpairmentFA.FixedAssets AS ImpairmentOfVNAPre
		|		INNER JOIN Document.ImpairmentFA.FixedAssets AS ImpairmentOfVNACur
		|		ON (ImpairmentOfVNACur.FixedAsset = ImpairmentOfVNAPre.FixedAsset)
		|WHERE
		|	ImpairmentOfVNAPre.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND ImpairmentOfVNAPre.Ref.Organization = &Organization
		|	AND ImpairmentOfVNAPre.Ref.Posted
		|	AND ImpairmentOfVNAPre.Ref <> &CurrentDocument
		|	AND ImpairmentOfVNACur.Ref = &CurrentDocument
		|
		|GROUP BY
		|	ImpairmentOfVNAPre.Ref,
		|	ImpairmentOfVNAPre.FixedAsset
		|
		|UNION ALL
		|
		|SELECT
		|	ImpairmentOfVNAPre.Ref,
		|	ImpairmentOfVNAPre.IntangibleAsset,
		|	""IntangibleAssets""
		|FROM
		|	Document.ImpairmentFA.IntangibleAssets AS ImpairmentOfVNAPre
		|		INNER JOIN Document.ImpairmentFA.IntangibleAssets AS ImpairmentOfVNACur
		|		ON (ImpairmentOfVNACur.IntangibleAsset = ImpairmentOfVNAPre.IntangibleAsset)
		|WHERE
		|	ImpairmentOfVNAPre.Ref.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND ImpairmentOfVNAPre.Ref.Organization = &Organization
		|	AND ImpairmentOfVNAPre.Ref.Posted
		|	AND ImpairmentOfVNAPre.Ref <> &CurrentDocument
		|	AND ImpairmentOfVNACur.Ref = &CurrentDocument
		|
		|GROUP BY
		|	ImpairmentOfVNAPre.Ref,
		|	ImpairmentOfVNAPre.IntangibleAsset";
	
	Query.SetParameter("CurrentDocument", Ref);
	Query.SetParameter("BeginOfPeriod", BegOfMonth(Date));
	Query.SetParameter("EndOfPeriod", EndOfMonth(Date));
	Query.SetParameter("Organization", Organization);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Cancel = True;
		
		SelectionDetailRecords = QueryResult.Select();

		PathPattern = "Object.%1";
		MessageText = NStr("vi = 'Đối với đối tượng %1 trong kỳ này đã nhập chứng từ %2. Cần hủy kết chuyển chứng từ trước đó';
							|ru = 'Для объекта %1 в данном периоде уже введен документ %2. Необходимо отменить проведение предыдущего документа';
							|en = 'The %2 document has already been entered for the %1 object in this period. Cancel posting of the previous document'; fa = 'The %2 document has already been entered for the %1 object in this period. Cancel posting of the previous document';
							|it = 'Per l''oggetto %1 è già stato inserito il documento %2 in questo periodo. È necessario annullare la registrazione del documento precedente';
							|pl = 'Dla obiektu %1 w bieżącym okresie jest już zatwierdzony dokument %2. Należy anulować zatwierdzenie poprzedniego dokumentu';
							|tr = 'Belge %2, verilen dönemde nesne %1 için zaten girilmiştir. Önceki belgenin yürütülmesini iptal etmek gerekir'");
		
		While SelectionDetailRecords.Next() Do
			
			Common.MessageToUser(
				StrTemplate(MessageText, SelectionDetailRecords.NCA, SelectionDetailRecords.ImpairmentDocument)
				,,StrTemplate(PathPattern, SelectionDetailRecords.TS),,Cancel);
			
		EndDo;
	EndIf;
	
EndProcedure

Procedure CreateTaskForEndOfMonth()

	CompanyArray = New Array();
	CompanyArray.Add(Organization);
	
	InformationRegisters.JobsForMonthEndClosing.CreateRegisterEntry(
			BegOfMonth(Date), Ref, Organization, Catalogs.MonthEndClosingOperations.ImpairmentFA);
	
EndProcedure

Procedure CheckAnalyticsOfArticle(CheckedAttributes, AssetRef, NameOfAnalyticsProps)
	DimensionAttributeToCheck = CheckedAttributes.Find(NameOfAnalyticsProps);
	If ValueIsFilled(AssetRef)
			And Not Common.ObjectAttributeValue(AssetRef, "ControlDimensionFilling")
			And DimensionAttributeToCheck <> Undefined Then
		CheckedAttributes.Delete(DimensionAttributeToCheck);
	EndIf;
EndProcedure

#EndRegion

#EndIf
