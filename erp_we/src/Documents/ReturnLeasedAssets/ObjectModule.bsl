#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	If FillInDataType = Type("Structure") And FillingData.Property("DocumentBasis") Then
		FillInDataType = TypeOf(FillingData.DocumentBasis);
	EndIf;
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData, StandardProcessing);
	ElsIf FillInDataType = Type("DocumentRef.ReceiveLeasedAssets") Then
		FillInBasedOnReceiptOfLeasedFA(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.Counterparties") Then
		FillInBasedOnCounterparty(FillingData, StandardProcessing);
	EndIf;
	
	ReturnLeasedAssetsLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);
	
	InitializeDocument();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "FA");
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "FA");
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NonCurrentAssets.CheckAbsenceOfDuplicatesInTablePart(ThisObject, "FA", "FixedAsset", Cancel);
		
	CheckThatFAIsReceivedForRent(Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	ReturnLeasedAssetsLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
EndProcedure

Procedure FillInSelectionDocument(Basis, StandardProcessing)

	If Basis.Property("Counterparty") Then
		FillInBasedOnCounterparty(Basis.Counterparty, StandardProcessing);
	EndIf; 
	
EndProcedure

Procedure FillInBasedOnReceiptOfLeasedFA(FillingData)
	
	Query = New Query;
	Query.SetParameter("FillingData", FillingData);
	Query.Text =
	"SELECT
	|	ReceiveLeasedAssets.Organization AS Organization,
	|	ReceiveLeasedAssets.Counterparty AS Counterparty,
	|	ReceiveLeasedAssets.Contract AS Contract,
	|	ReceiveLeasedAssets.Department AS Department,
	|
	|	ReceiveLeasedAssets.FA.(
	|		FixedAsset AS FixedAsset
	|	)
	|FROM
	|	Document.ReceiveLeasedAssets AS ReceiveLeasedAssets
	|WHERE
	|	ReceiveLeasedAssets.Ref = &FillingData";
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	FillPropertyValues(ThisObject, Selection);
	FA.Load(Selection.FA.Unload());
	
EndProcedure

Procedure FillInBasedOnCounterparty(Basis, StandardProcessing)

	If Not ValueIsFilled(Basis) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	Counterparty = Basis;
	
	MessageText = Documents.ReturnLeasedAssets.FillInReceivedRentFromCounterparty(ThisObject);
	If MessageText <> Undefined Then
		Raise MessageText;
	EndIf;
	
EndProcedure

Procedure CheckThatFAIsReceivedForRent(Cancel)

	If Not ValueIsFilled(Counterparty)
		Or Not ValueIsFilled(Organization) Then
		Return;
	EndIf; 
	
	QueryText = 
	"SELECT
	|	FATable.LineNumber AS LineNumber,
	|	FATable.FixedAsset AS FixedAsset
	|INTO FATable
	|FROM
	|	&FATable AS FATable
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FATable.LineNumber AS LineNumber,
	|	CAST(FATable.FixedAsset AS Catalog.Assets).Presentation AS FixedAssetPresentation,
	|	FALocation.Organization AS Organization,
	|	FALocation.Organization.Presentation AS OrganizationPresentation,
	|	LeasedAsset.Counterparty AS Counterparty,
	|	LeasedAsset.Counterparty.Presentation AS LessorPresentation
	|FROM
	|	FATable AS FATable
	|		LEFT JOIN InformationRegister.FALocation.SliceLast(
	|				&Date,
	|				Recorder <> &Recorder
	|					AND CorrectionDate = DATETIME(1,1,1)
	|					AND FixedAsset IN
	|						(SELECT
	|							FATable.FixedAsset
	|						FROM
	|							FATable)) AS FALocation
	|		ON (FALocation.FixedAsset = FATable.FixedAsset)
	|
	|		LEFT JOIN InformationRegister.LeasedAsset.SliceLast(
	|				&Date,
	|				Recorder <> &Recorder
	|					AND FixedAsset IN
	|						(SELECT
	|							FATable.FixedAsset
	|						FROM
	|							FATable)) AS LeasedAsset
	|		ON (LeasedAsset.FixedAsset = FALocation.FixedAsset)
	|			AND (LeasedAsset.State = VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting))
	|
	|WHERE
	|	(FALocation.Organization <> &Organization
	|			OR LeasedAsset.Counterparty <> &Counterparty
	|			OR LeasedAsset.FixedAsset IS NULL)
	|
	|ORDER BY
	|	LineNumber";
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Recorder", Ref);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("FATable", FA.Unload());
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		Path = CommonClientServer.PathToTabularSection("FA", Selection.LineNumber, "FixedAsset");
		
		If Not ValueIsFilled(Selection.Organization)
			Or Not ValueIsFilled(Selection.Counterparty) Then
			
			MessageText = NStr("vi = 'Tài sản cố định ""%1"" không được tính là đã nhận vào thuê %2';
								|ru = 'Основное средство ""%1"" не числится полученным в аренду на %2';
								|en = 'Asset ""%1"" is not registered as leased as for %2'; fa = 'Asset ""%1"" is not registered as leased as for %2';
								|it = 'L''immobilizzazione ""%1"" non risulta ricevuta in affitto per %2';
								|pl = 'Środek trwały ""%1"" nie liczy się za otrzymany do dzierżawy na %2';
								|tr = 'Sabit kıymetler ""%1"" %2''ye kiralanmamıştır'");
			MessageText = StrTemplate(MessageText, Selection.FixedAssetPresentation, Format(Date, "DLF=D"));
			
		ElsIf Selection.Organization <> Organization Then
			
			MessageText = NStr("vi = 'Tài sản cố định ""%1"" đã được nhận vào thuê cho doanh nghiệp khác ""%2""';
								|ru = 'Основное средство ""%1"" получено в аренду в другую организацию ""%2""';
								|en = 'Asset ""%1"" is received for lease to the other company ""%2""'; fa = 'Asset ""%1"" is received for lease to the other company ""%2""';
								|it = 'Immobilizzazione ""%1"" ricevuta in affitto da un''altra organizzazione ""%2""';
								|pl = 'Środek trwały ""%1"" jest otrzymany do dzierżawy do innej firmy ""%2""';
								|tr = '""%1"" sabit kıymeti başka bir ""%2"" iş yeri tarafından kiralanmıştır'");
			MessageText = StrTemplate(MessageText, Selection.FixedAssetPresentation, Selection.OrganizationPresentation);

		ElsIf Selection.Counterparty <> Counterparty Then
			
			MessageText = NStr("vi = 'Tài sản cố định ""%1"" đã nhận vào thuê từ người cho thuê khác ""%2""';
								|ru = 'Основное средство ""%1"" получено в аренду от другого арендодателя ""%2""';
								|en = 'Asset ""%1"" is received for lease from the other lessor ""%2""'; fa = 'Asset ""%1"" is received for lease from the other lessor ""%2""';
								|it = 'Immobilizzazione ""%1"" ricevuta in affitto da un altro locatore ""%2""';
								|pl = 'Środek trwały ""%1"" otrzymano do dzierżawy od innego wynajmującego ""%2""';
								|tr = 'Sabit kıymet ""%1"" başka bir ""%2"" kiraya vereninden kiralanmıştır'");
			MessageText = StrTemplate(MessageText, Selection.FixedAssetPresentation, Selection.LessorPresentation);
			
		EndIf; 
		
		CommonClientServer.MessageToUser(MessageText, ThisObject, Path,, Cancel);
	
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
