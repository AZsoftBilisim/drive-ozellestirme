#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Generates a table of document amounts in regulated and management accounting currencies.
// Saves the recalculated document data to the document summation register in the accounting report.
// 
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 		                                         If Undefined, it initializes only the total of the documents in the accounting report.
// 	RequestTextForTheseDocuments - String - Request data sources of documents that are used for conducting and need to be recalculated
// 		Description of Query Text fields:
//        The data sourcesource - String - The name of the data source - is a data recalculation granule. For example, "Products".
//        Distribute the total sum - Boolean - If True, then the total amount of the source is recalculated into accounting currencies and distributed to the lines.
//                                          If it is False, then a line-by-line recalculation of the amounts at the exchange rate is performed.
//        
//        Link - Documentlink - Link to the document
//        Date - Date is the date of the document.
//        Organization - Directory link.Organizations - Document organization.
//        The document's currency is a reference link.Currencies - The Currency of the document.
//        Foreign Exchange - Reference Booklink.Currencies - The currency of mutual settlements with the client or supplier. It must be specified if the type of settlement is filled in.
//        PeriodBazyNDS - Date - The date on which the VAT base is determined.
//        Datacourse - Date - The date for getting exchange rates.
//        
//        Line number - Number is the line number of the table part. If the data is obtained by header, then 0.
//        Line Identifier - A string is a unique identifier of document data (it can be specified both for a row in the table part and for the "header" of the document).
//        
//        SummaBesNDS - Number - The amount of VAT per line in the document currency.
//        StavkaNDS - Listing link.StavkiNDS - The VAT rate in the line of the table part or in the "header" of the document.
//        SummaNDS - Number - VAT amount per line in the document currency.
//        Sum of mutual settlements - Number - Amount in the currency of mutual settlements.
//        The sum of mutual settlements is the number of VAT amounts in the currency of mutual settlements.
//        SummaBesNDSRegl - Number - Amount excluding VAT in the currency of regulated accounting.
//        SummaBezNDSUpr - Number - Amount excluding VAT in the currency of management accounting.
//        
//        Reflected in settlements - Boolean - A sign that the line affects settlements with counterparties (forms actual or planned debt) 
//        Object of accounts - UNDEFINED, Reference link.Calculation objectsthe calculation object must be filled in if the calculation is reflected = True
//        Recalculate the data of settlements - Boolean - A sign that it is required to recalculate the amounts in the currency of Local. and accounting management according to the data of mutual settlements.
//                                                 Recalculation is necessary if the document sets off advances.
// 	DoNotRecalculateVATAmounts - Boolean - If True, the SummaNDSRegl and SummaNDSUpr fields are taken from the data source.
//
// Query Text template
// 	SELECT
//	|	""Document dataedocument"" AS A DATA SourcedoCument,
//	|T Lay OUT HOW TO distribute the total sum,
//	|	 Document table.Link AS A Link,
//	|	 Document table.Date AS A Date,
//	|	 Document table.Organization AS an Organization,
//	|	 Document table.Currency AS A document's currency,
//	|	 Document table.Currency OF MUTUAL SETTLEMENTS AS currency OF MUTUAL settlements,
//	|	 Document table.Date AS A PeriodBaziNDS,
//	|	 Document table.Date AS A Datacourse,
//	|
//	|	0 AS A LINE NUMBER,
//	|	"""" AS A STRING ID,
//	|	 Document table.SummaSNDS - Document tablesadocument.SummaNDS AS SummaBesNDS,
//	|	 Document table.StavkaNDS AS StavkaNDS,
//	|	 Document table.SummaNDS AS SummaNDS,`
//	|	 Document table.SUMMATION of MUTUAL SETTLEMENTS AS SUMMATION OF MUTUAL SETTLEMENTS,
//	|	 Document table.SUMMANDSWIMOCALCULATIONS AS SUMMANDSWIMOCALCULATIONS,
//	|	0 AS SumabEsnDSREgle,
//	|	0 AS SUMABESNDSUPR,
//	|	
//	|T Truth AS reflected in the calculations,
//	|	 Document table.ACCOUNTING OBJECTS AS ACCOUNTING OBJECTS,
//	|TTHE TRUTH IS HOW to RECALCULATE the calculation data
//	|FROM
//	|	<Document full nameadocument > AS document tablesadocument
//	|
//	|WHERE
//	|	 Document table.Link In (&Link)".
//
Procedure GenerateAccordingToDocument(Query,
	QueryTexts,
	Registers,
	RequestTextForTheseDocuments,
	DoNotRecalculateVATAmounts = False) Export
	
	RegisterName = Metadata.InformationRegisters.DocumentAmountsInAccountingCurrency.Name;
	If Registers <> Undefined And Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	If Query.TempTablesManager = Undefined Then
		Query.TempTablesManager = New TempTablesManager();
	EndIf;
	
	If DocumentsPosting.ThereIsQueryTable("TTAmountsOfDocumentsInAccountingCurrencies", QueryTexts) 
		Or Query.TempTablesManager.Tables.Find("TTAmountsOfDocumentsInAccountingCurrencies") <> Undefined Then
		Return;
	EndIf;
	
	RowsArray = New Array();
	
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	If Not ValueIsFilled(ManagementAccountingCurrency) Then
		RowsArray.Add(NStr("vi = 'Chưa điền tiền tệ kế toán quản trị';
							|ru = 'Не заполнена валюта управленческого учета';
							|en = 'Management accounting currency is not filled in'; fa = 'Management accounting currency is not filled in';
							|it = 'Non è stata compilata la valuta della contabilità regolatoria';
							|pl = 'Nie wypełniono waluty ewidencji zarządczej';
							|tr = 'Yönetim muhasebesi para birimi doldurulmadı'"));
	EndIf;
	
	If RowsArray.Count() > 0 Then
		RowsArray.Add(NStr("vi = 'Để tùy chỉnh, cần chuyển đến phân hệ ""Danh mục và quản trị""-""Tập đoàn""-""Tiền tệ"".';
							|ru = 'Для настройки необходимо перейти в раздел ""НСИ и администрирование""-""Предприятие""-""Валюты"".';
							|en = 'To set it up, go to ""Master data and settings"" - ""Enterprise"" - ""Currencies"".'; fa = 'To set it up, go to ""Master data and settings"" - ""Enterprise"" - ""Currencies"".';
							|it = 'Per l''impostazione è necessario passare al reparto ""Informazioni di riferimento e amministrazione""-""Impresa""-""Valute"".';
							|pl = 'W celu ustawienia należy przejść do rozdziału ""Ustawienia""-""Przedsiębiorstwo""-""Waluty"".';
							|tr = 'Ayarları yapılandırmak için ""Master veri ve yönetim""-""İşletme""-""Para Birimleri"" bölümüne git.'"));
		Raise StrConcat(RowsArray, Chars.LF);
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.DataSource              AS DataSource,
	|	DocumentData.DistributeTotalAmount      AS DistributeTotalAmount,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Date                        AS Period,
	|	DocumentData.Organization                 AS Organization,
	|	DocumentData.DocumentCurrency             AS Currency,
	|	CASE
	|		WHEN DocumentData.ARAPCurrency = UNDEFINED
	|			THEN ISNULL(ARAPObjects.ARAPCurrency, UNDEFINED) 
	|		ELSE DocumentData.ARAPCurrency 
	|	END                                       AS ARAPCurrency,
	|	&TextOfVATBasePeriodField                     AS VATBasePeriod,
	|	DocumentData.DateOfCourse                   AS DateOfCourse,
	|
	|	DocumentData.LineNumber                 AS LineNumber,
	|	DocumentData.RowID         AS RowID,
	|	DocumentData.AmountExcludingVAT                 AS AmountExcludingVAT,
	|	DocumentData.VATRate                   AS VATRate,
	|	DocumentData.VATAmount                    AS VATAmount,
	|	DocumentData.AmountARAP         AS AmountARAP,
	|	DocumentData.AmountVATARAP      AS AmountVATARAP,
	|	DocumentData.AmountExcludingVATCompl             AS AmountExcludingVATCompl,
	|	DocumentData.AmountExcludingVATMan              AS AmountExcludingVATMan,
	|	&TextOfVATAmountLocalField AS VATAmountCompl,
	|	&TextOfVATAmountManField AS VATAmountMan,
	|	
	|	DocumentData.RecordedInARAPAccounting AS RecordedInARAPAccounting,
	|	DocumentData.ARAPObject      AS ARAPObject,
	|	DocumentData.RecalculateBasedOnARAPData AS RecalculateBasedOnARAPData,
	|	&DoNotRecalculateVATAmounts AS DoNotRecalculateVATAmounts,
	|	ISNULL(ARAPObjects.Contract, UNDEFINED) AS Contract,
	|	ISNULL(
	|		ARAPObjects.Contract.ContractRateOption, 
	|		VALUE(Enum.ContractRateOptions.Mutable)) AS ContractRateOption
	|	
	|INTO DocumentDataPreliminary
	|FROM
	|	&RequestTextForTheseDocuments AS DocumentData
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON (DocumentData.ARAPObject = ARAPObjects.Ref)
	|
	|INDEX BY
	|	Recorder,
	|	RowID
	|";
	QueryText = StrReplace(QueryText, "&RequestTextForTheseDocuments", "(" + RequestTextForTheseDocuments + ")");
	
	If DoNotRecalculateVATAmounts Then
		
		TextOfVATAmountLocalField = "DocumentData.VATAmountCompl";
		TextOfVATAmountManField = "DocumentData.VATAmountMan";
		TextOfVATBasePeriodField = "DATETIME(1, 1, 1)";
		
	Else
		
		TextOfVATAmountLocalField = "0";
		TextOfVATAmountManField = "0";
		TextOfVATBasePeriodField = "DocumentData.VATBasePeriod";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,
		"&TextOfVATAmountLocalField",
		TextOfVATAmountLocalField);
	
	QueryText = StrReplace(QueryText,
		"&TextOfVATAmountManField",
		TextOfVATAmountManField);
	
	QueryText = StrReplace(QueryText,
		"&TextOfVATBasePeriodField",
		TextOfVATBasePeriodField);
	
	InitializationRequest = New Query;
	InitializationRequest.TempTablesManager = Query.TempTablesManager;
	InitializationRequest.SetParameter("ManagementAccountingCurrency", ManagementAccountingCurrency);
	InitializationRequest.SetParameter("DoNotRecalculateVATAmounts", DoNotRecalculateVATAmounts);
	For Each Parameter In Query.Parameters Do
		InitializationRequest.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	InitializationRequest.Text = QueryText;
	InitializationRequest.Execute();
	
	ConvertTableToAccountingCurrencies(InitializationRequest.TempTablesManager);
	
	InitializationRequest.Text =
	"SELECT
	|	DocumentsData.DataSource                          AS DataSource,
	|	DocumentsData.DistributeTotalAmount                  AS DistributeTotalAmount,
	|	DocumentsData.Recorder                             AS Ref,
	|	DocumentsData.Period                                  AS Date,
	|	DocumentsData.Organization                             AS Organization,
	|	DocumentsData.Currency                                  AS DocumentCurrency,
	|	DocumentsData.ARAPCurrency                    AS ARAPCurrency,
	|	DocumentsData.VATBasePeriod                           AS VATBasePeriod,
	|
	|	DocumentsData.RowID                     AS RowID,
	|	DocumentsData.LineNumber                             AS LineNumber,
	|	DocumentsData.VATRate                               AS VATRate,
	|	DocumentsData.AmountExcludingVAT + DocumentsData.VATAmount AS AmountIncludingVAT,
	|	DocumentsData.VATAmount                                AS VATAmount,
	|	DocumentsData.AmountExcludingVAT                             AS AmountExcludingVAT,
	|	DocumentsData.AmountARAP                     AS AmountARAP,
	|	DocumentsData.AmountVATARAP                  AS AmountVATARAP,
	|	
	|	DocumentsData.RecordedInARAPAccounting AS RecordedInARAPAccounting,
	|	DocumentsData.ARAPObject AS ARAPObject,
	|	DocumentsData.RecalculateBasedOnARAPData AS RecalculateBasedOnARAPData,
	|	DocumentsData.DoNotRecalculateVATAmounts AS DoNotRecalculateVATAmounts,
	|	
	|	ISNULL(Amounts.AmountExcludingVATMan + Amounts.VATAmountMan,
	|		CASE
	|			WHEN DocumentsData.ARAPCurrency = &ManagementAccountingCurrency 
	|			      AND DocumentsData.Currency <> DocumentsData.ARAPCurrency
	|				THEN DocumentsData.AmountARAP
	|			ELSE DocumentsData.AmountExcludingVATMan + DocumentsData.VATAmountMan
	|		END) AS AmountIncludingVATMan,
	|
	|	ISNULL(Amounts.AmountExcludingVATMan,
	|		CASE 
	|			WHEN DocumentsData.ARAPCurrency = &ManagementAccountingCurrency
	|			      AND DocumentsData.Currency <> DocumentsData.ARAPCurrency
	|			      AND DocumentsData.AmountVATARAP <> 0
	|				THEN DocumentsData.AmountARAP - DocumentsData.AmountVATARAP
	|			ELSE DocumentsData.AmountExcludingVATMan
	|		END) AS AmountExcludingVATMan,
	|
	|	ISNULL(Amounts.VATAmountMan,
	|		CASE
	|			WHEN DocumentsData.ARAPCurrency = &ManagementAccountingCurrency 
	|			      AND DocumentsData.Currency <> DocumentsData.ARAPCurrency
	|			      AND DocumentsData.AmountVATARAP <> 0
	|				THEN DocumentsData.AmountVATARAP
	|			ELSE DocumentsData.VATAmountMan
	|		END) AS VATAmountMan,
	|
	|	ISNULL(Amounts.AmountExcludingVATCompl,
	|		CASE
	|			WHEN DocumentsData.ARAPCurrency = Companies.LocalAccountingCurrency
	|			      AND DocumentsData.Currency <> DocumentsData.ARAPCurrency
	|			      AND DocumentsData.AmountVATARAP <> 0
	|				THEN DocumentsData.AmountARAP - DocumentsData.AmountVATARAP
	|			ELSE DocumentsData.AmountExcludingVATCompl 
	|		END 
	|	) AS AmountExcludingVATCompl,
	|
	|	ISNULL(Amounts.VATAmountCompl, 
	|		CASE
	|			WHEN DocumentsData.ARAPCurrency = Companies.LocalAccountingCurrency 
	|			      AND DocumentsData.Currency <> DocumentsData.ARAPCurrency
	|			      AND DocumentsData.AmountVATARAP <> 0
	|				THEN DocumentsData.AmountVATARAP
	|			ELSE DocumentsData.VATAmountCompl
	|		END
	|	) AS VATAmountCompl,
	|
	|	ISNULL(Amounts.AmountExcludingVATCompl + Amounts.VATAmountCompl,
	|		CASE
	|			WHEN DocumentsData.ARAPCurrency = Companies.LocalAccountingCurrency
	|			      AND DocumentsData.Currency <> DocumentsData.ARAPCurrency
	|			      AND DocumentsData.AmountARAP <> 0
	|				THEN DocumentsData.AmountARAP
	|			ELSE DocumentsData.AmountExcludingVATCompl + DocumentsData.VATAmountCompl
	|		END
	|	) AS AmountIncludingVATCompl,
	|
	|	CASE
	|		WHEN DocumentsData.Recorder REFS Document.CustomerInvoice
	|			AND CAST(DocumentsData.Recorder AS Document.CustomerInvoice).BusinessOperation =
	|				VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|				OR DocumentsData.Recorder REFS Document.SaleAdjustment
	|					AND CAST(DocumentsData.Recorder AS Document.SaleAdjustment).BusinessOperation =
	|						VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|			THEN 0
	|		ELSE
	|			ISNULL(Amounts.VATBaseLocal,
	|				CASE
	|					WHEN DocumentsData.VATRate IN (VALUE(Catalog.VATRates.EmptyRef), UNDEFINED)
	|						THEN 0
	|					WHEN DocumentsData.ARAPCurrency = Companies.LocalAccountingCurrency
	|					      AND DocumentsData.Currency <> DocumentsData.ARAPCurrency
	|					      AND DocumentsData.AmountVATARAP <> 0
	|					THEN DocumentsData.AmountARAP - DocumentsData.AmountVATARAP
	|					ELSE DocumentsData.VATBaseLocal
	|				END 
	|			)
	|	END AS VATBaseLocal,
	|
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGiven, 0) = 0
	|			THEN DocumentsData.AmountARAP - DocumentsData.AmountVATARAP
	|		ELSE Amounts.AmountGiven
	|	END AS AmountGiven,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) = 0
	|			THEN ISNULL(Amounts.AmountExcludingVATCompl,
	|					CASE
	|						WHEN DocumentsData.ARAPCurrency = Companies.LocalAccountingCurrency
	|						      AND DocumentsData.Currency <> DocumentsData.ARAPCurrency
	|						      AND DocumentsData.AmountVATARAP <> 0
	|							THEN DocumentsData.AmountARAP - DocumentsData.AmountVATARAP
	|						ELSE DocumentsData.AmountExcludingVATCompl 
	|					END)
	|		ELSE Amounts.AmountGivenCompl
	|	END AS AmountGivenCompl,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) = 0
	|			THEN ISNULL(Amounts.AmountExcludingVATMan,
	|					CASE 
	|						WHEN DocumentsData.ARAPCurrency = &ManagementAccountingCurrency
	|						      AND DocumentsData.Currency <> DocumentsData.ARAPCurrency
	|						      AND DocumentsData.AmountVATARAP <> 0
	|							THEN DocumentsData.AmountARAP - DocumentsData.AmountVATARAP
	|						ELSE DocumentsData.AmountExcludingVATMan
	|					END)
	|		ELSE Amounts.AmountGivenMan
	|	END AS AmountGivenMan,
	|	CASE
	|		WHEN Amounts.Recorder IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS FromRegister
	|
	|INTO TTAmountsOfDocumentsInAccountingCurrencies
	|FROM
	|	DocumentAmountsInAccountingCurrency AS DocumentsData
	|
	|	INNER JOIN Catalog.Companies AS Companies
	|		ON Companies.Ref = DocumentsData.Organization
	|	
	|	LEFT JOIN 
	|		InformationRegister.DocumentAmountsInAccountingCurrency AS Amounts
	|	ON
	|		DocumentsData.Recorder = Amounts.Recorder
	|		AND DocumentsData.Period = Amounts.Period
	|		AND DocumentsData.RowID = Amounts.RowID
	|		AND DocumentsData.ARAPCurrency = Amounts.ARAPCurrency
	|		AND DocumentsData.Currency = Amounts.Currency
	|		AND DocumentsData.VATRate = Amounts.VATRate
	|		AND DocumentsData.AmountARAP = Amounts.AmountARAP
	|		AND DocumentsData.AmountExcludingVAT = Amounts.AmountExcludingVAT
	|		AND DocumentsData.VATAmount = Amounts.VATAmount
	|		AND DocumentsData.Currency = Amounts.Currency
	|		AND DocumentsData.ARAPCurrency = Amounts.ARAPCurrency
	|		AND DocumentsData.VATBasePeriod = Amounts.VATBasePeriod
	|		AND DocumentsData.RecordedInARAPAccounting = Amounts.RecordedInARAPAccounting
	|		AND DocumentsData.ARAPObject = Amounts.ARAPObject
	|		AND DocumentsData.RecalculateBasedOnARAPData = Amounts.RecalculateBasedOnARAPData
	|		AND DocumentsData.DoNotRecalculateVATAmounts = Amounts.DoNotRecalculateVATAmounts
	|
	|INDEX BY
	|	Ref,
	|	RowID
	|;
	|
	|//////////////////////////////////////////////////////////////
	|DROP DocumentAmountsInAccountingCurrency
	|";
	SetPrivilegedMode(True);
	InitializationRequest.Execute();
	SetPrivilegedMode(False);
	
	If DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		
		If Not Query.Parameters.Property("ManagementAccountingCurrency") Then
			Query.SetParameter("ManagementAccountingCurrency",     ManagementAccountingCurrency);
		EndIf;
		
		QueryText = 
		"SELECT
		|	Amounts.Ref AS Recorder,
		|	Amounts.Date AS Period,
		|	
		|	Amounts.RowID AS RowID,
		|	
		|	Amounts.AmountExcludingVAT AS AmountExcludingVAT,
		|	Amounts.VATAmount  AS VATAmount,
		|	
		|	Amounts.AmountExcludingVATCompl AS AmountExcludingVATCompl,
		|	Amounts.VATBaseLocal AS VATBaseLocal,
		|	Amounts.VATAmountCompl AS VATAmountCompl,
		|	Amounts.AmountExcludingVATMan AS AmountExcludingVATMan,
		|	Amounts.VATAmountMan AS VATAmountMan,
		|	Amounts.AmountARAP  AS AmountARAP,
		|	Amounts.AmountVATARAP  AS AmountVATARAP,
		|	
		|	Amounts.DocumentCurrency AS Currency,
		|	Amounts.ARAPCurrency AS ARAPCurrency,
		|	Amounts.VATRate AS VATRate,
		|	
		|	Amounts.VATBasePeriod AS VATBasePeriod,
		|
		|	Amounts.RecordedInARAPAccounting AS RecordedInARAPAccounting,
		|	CASE
		|		WHEN NOT Amounts.RecordedInARAPAccounting
		|			THEN UNDEFINED
		|		ELSE Amounts.ARAPObject
		|	END AS ARAPObject,
		|	(Amounts.RecordedInARAPAccounting AND Amounts.RecalculateBasedOnARAPData) AS RecalculateBasedOnARAPData,
		|	Amounts.DoNotRecalculateVATAmounts AS DoNotRecalculateVATAmounts,
		|	CASE
		|		WHEN (Amounts.RecordedInARAPAccounting AND Amounts.RecalculateBasedOnARAPData)
		|			THEN ISNULL(Amounts.ARAPObject.PaymentType_, UNDEFINED)
		|		ELSE UNDEFINED
		|	END AS PaymentType_,
		|	Amounts.AmountGiven AS AmountGiven,
		|	Amounts.AmountGivenMan AS AmountGivenMan,
		|	Amounts.AmountGivenCompl AS AmountGivenCompl
		|
		|FROM
		|	TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
		|	LEFT JOIN
		|		Catalog.ARAPObjects AS ARAPObjects
		|	ON
		|		Amounts.ARAPObject = ARAPObjects.Ref
		|
		|ORDER BY
		|	Amounts.DataSource,
		|	Amounts.LineNumber";
		
		QueryTexts.Add(QueryText, RegisterName);
	
	EndIf;
	
EndProcedure

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.DocumentAmountsInAccountingCurrency);
		
	EndIf;
	
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		Parameters.TaskControlRegisters.Add(Metadata.InformationRegisters.DocumentAmountsInAccountingCurrency);
		
	EndIf;
	
	Parameters.CompletingTasksInNonOperationalQueue = True;

	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	QueriesTexts = New Map();
	
	Return QueriesTexts;
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements on the register.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "DocumentAmountsInAccountingCurrency");
	
EndProcedure

#EndRegion

// Synchronization of regl. amounts in accounting registers according to the Totalsdocumentsvalyutahucheta
// Parameters:
// 	AmountRegistrars - DocumentRef, Array - a single document Link or an array of document Link types.
Procedure UpdateDocumentRegisteredRecords_(AmountRegistrars) Export
	
	Recorders = TMCommonUseClientServer.Array(AmountRegistrars);
	For Each Ref In Recorders Do
		
		RefType = TypeOf(Ref);
		
		UpdateComposition = New Structure();
		
		CommonClientServer.SupplementStructure(UpdateComposition, VATAccountingERP.VATRegisters_());
		
		If RefType <> Type("DocumentRef.CustomerInvoice")
			And RefType <> Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
			// Cost registers are added to the update for all documents, with the exception of sales documents, which can be processed "on the go".
			// In the documents, the implementation of the movement at cost does not depend on mutual settlements, but in case of double-checking, there is a risk of changing the data on the date of shipment "on the way".
			UpdateComposition.Insert("InventoryCost", AccumulationRegisters.InventoryCost.CreateRecordSet());
			UpdateComposition.Insert("OtherExpenses", AccumulationRegisters.OtherExpenses.CreateRecordSet());
			UpdateComposition.Insert("ItemisedExpensesLots", AccumulationRegisters.ItemisedExpensesLots.CreateRecordSet());
		EndIf;
				
		UpdateComposition.Insert("OtherIncome", AccumulationRegisters.OtherIncome.CreateRecordSet());
		UpdateComposition.Insert("RevenueServicesAndAssets", AccumulationRegisters.RevenueServicesAndAssets.CreateRecordSet());
		
		UpdateComposition.Insert("RevenueAndCOGS", AccumulationRegisters.RevenueAndCOGS.CreateRecordSet());
		UpdateComposition.Insert("Purchases", AccumulationRegisters.Purchases.CreateRecordSet());
		UpdateComposition.Insert("OtherAssetsLiabilities", AccumulationRegisters.OtherAssetsLiabilities.CreateRecordSet());
		UpdateComposition.Insert("RecordsCounterpartyIncomeExpenses", AccumulationRegisters.RecordsCounterpartyIncomeExpenses.CreateRecordSet());
		UpdateComposition.Insert("RecordsCounterpartyCounterparty", AccumulationRegisters.RecordsCounterpartyCounterparty.CreateRecordSet());
		UpdateComposition.Insert("OtherAssetsAndLiabilitiesRecords", AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.CreateRecordSet());
		UpdateComposition.Insert("GoodsToBeRegisteredInReportsToConsignor", AccumulationRegisters.GoodsToBeRegisteredInReportsToConsignor.CreateRecordSet());
		UpdateComposition.Insert("ServicesForRegistrationOfReportsToPrincipal", AccumulationRegisters.ServicesForRegistrationOfReportsToPrincipal.CreateRecordSet());
		UpdateComposition.Insert("GoodsAndServicesToRegisterPurchasingReportsToConsignor", AccumulationRegisters.GoodsAndServicesToRegisterPurchasingReportsToConsignor.CreateRecordSet());
		UpdateComposition.Insert("LossAllowance", AccumulationRegisters.LossAllowance.CreateRecordSet());
		UpdateComposition.Insert("InvestmentInRent", AccumulationRegisters.InvestmentInRent.CreateRecordSet());
		PartyRegisters = CalculationOfCostLocalization.PartyRegisters_();
		CommonClientServer.SupplementStructure(UpdateComposition, PartyRegisters);
		
		
		UpdateDocumentRegisteredRecords(Ref, UpdateComposition);
		
		If GetFunctionalOption("UseDocumentCorrection") Then
			DocumentsStorno = DocumentCorrection.StornoDocuments(Ref);
			For Each TableRow In DocumentsStorno Do
				UpdateDocumentRegisteredRecords(TableRow.Ref, UpdateComposition);	
			EndDo;
		EndIf;
			
	EndDo;


	UpdateComposition = New Structure();
	CommonClientServer.SupplementStructure(UpdateComposition, VATAccountingERP.VATRegisters_());
	
	TaxInv = VATAccountingERP.InvoicesIssuedOnLegalGrounds(Recorders, True);
	For Each Document In TaxInv Do
		If Not Document.ManualAdjustmentOfDocumentAmounts
			And (Document.Corrective Or Document.Patch) Then
			// For corrections and corrections of the SF, we will re-send the document,
			// while the tabular part of the Goods is additionally refilled.
			
			DocumentObject = Document.Ref.GetObject();
			DocumentObject.AdditionalProperties.Insert("DocumentVerification_Disable", True);
			DocumentObject.Write(DocumentWriteMode.Posting);
		Else
			UpdateDocumentRegisteredRecords(Document.Ref, UpdateComposition);
		EndIf;
	EndDo;
	
	TaxInv = VATAccountingERP.InvoicesReceivedOnLegalGrounds(Recorders, True);
	For Each Document In TaxInv Do
		If Not Document.ManualAdjustmentOfDocumentAmounts Then
			DocumentObject = Document.Ref.GetObject();
			DocumentObject.AdditionalProperties.Insert("DocumentVerification_Disable", True);
			DocumentObject.Write(DocumentWriteMode.Posting);
		Else
			UpdateDocumentRegisteredRecords(Document.Ref, UpdateComposition);
		EndIf;
	EndDo;
	
	If GetFunctionalOption("UseBalanceSheetStatement")
		And Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		DataProcessors.FlowOfAssetsAndLiabilities.ReflectDocumentsInManagementBalanceSheet(Recorders);
		
	EndIf;// It is necessary to form an upr. balance
	
EndProcedure

// Starts the distribution of amounts in regulated and management accounting currencies, if necessary.
// The conditions of the conversion:
// 1.the account type details must be filled in in the accounting Totals register for the recalculated Registrar.
// 2. the Amount of lines in the currency of regulated or management accounting must differ from the amount of movements in the settlement registers.
// Parameters:
//		DocumentsArray - Array of DocumentRef - Array of documents that you want to test and run the conversion amounts.
// Returns:
//		Array of DocumentRef - an array of documents for which the data of the information register has been updated.
//
Function CalculateDocumentAmountsInAccountingCurrencies(DocumentsArray) Export
	
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");

	TableOfDocumentsForRecalculation = TableOfDocumentsForRecalculationOfAmountsInAccountingCurrencies(DocumentsArray);
	
	ArrayOfDocumentsWithClients = TableOfDocumentsForRecalculation.Copy(
		New Structure("PaymentType_",Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting)).UnloadColumn("ARAPDocument");
	ArrayOfDocumentsWithSuppliers = TableOfDocumentsForRecalculation.Copy(
		New Structure("PaymentType_",Enums.PartnersARAPAccountingTypes.VendorARAPAccounting)).UnloadColumn("ARAPDocument");
	
	If ArrayOfDocumentsWithClients.Count() > 0 Then
		CalculateAccordingToMutualSettlements("CustomersARAPAccounting", ArrayOfDocumentsWithClients);
	EndIf;
	If ArrayOfDocumentsWithSuppliers.Count() > 0 Then
		CalculateAccordingToMutualSettlements("VendorsARAPAccounting", ArrayOfDocumentsWithSuppliers);
	EndIf;
	
	ArrayOfChangedDocuments = New Array;
	CommonClientServer.SupplementArray(ArrayOfChangedDocuments, ArrayOfDocumentsWithClients);
	CommonClientServer.SupplementArray(ArrayOfChangedDocuments, ArrayOfDocumentsWithSuppliers);
	
	If NewOnlineARAPAccounting Then
		ArrayOfDocumentsForDiscounting = CommonClientServer.ArraysDifference(
			DocumentsArray,
			ArrayOfChangedDocuments);
		If ArrayOfDocumentsForDiscounting.Count() > 0 Then
			CommonClientServer.SupplementArray(
				ArrayOfChangedDocuments,
				CalculateDiscounting(ArrayOfDocumentsForDiscounting));
		EndIf;
	EndIf;
	
	Return ArrayOfChangedDocuments;
	
EndFunction

// A table of documents for recalculating amounts in accounting currencies.
// 
// Parameters:
//  DocumentsArray - Array of DocumentRef - array of documents
// 
// Returns:
//  ValueTable - Table Of Documents For Recalculation Of Amounts In Accounting Currencies
Function TableOfDocumentsForRecalculationOfAmountsInAccountingCurrencies(DocumentsArray) Export
	
	Query = New Query;
	Manager = New TempTablesManager;
	Query.TempTablesManager = Manager;
	
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	Query.SetParameter("DocumentsArray", DocumentsArray);
	Query.SetParameter("ThisIsTest", False);
	Query.SetParameter("CurrencyOfManAccounting", Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("NewOnlineARAPAccounting", NewOnlineARAPAccounting);
	Query.SetParameter("AccordingToAllDocuments", False);
	
	// Request for documents for which the amounts in accounting currencies do not match the settlement data.
	Query.Text = TextOfRequestForDocumentsToBeRecalculated();
	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	NumberOfResults = ResultsArray.Count();
	
	TableOfDocumentsForRecalculation = ResultsArray[NumberOfResults-1].Unload();

	Return TableOfDocumentsForRecalculation;
	
EndFunction

// Distributes amounts in regulated and management accounting currencies based on settlement data.
// 
// Parameters:
// 	PaymentType_ - String - The type of calculations, according to which you want to calculate the sum.
// 	                       It can take the values "calculated by Clients" or "calculated by Suppliers".
// 	DocumentsArray - Undefined, Array - Documents, which need to calculate the amount.
// 	                                          If Undefined, the calculation is performed for all documents.
//
Procedure CalculateAccordingToMutualSettlements(PaymentType_, DocumentsArray) Export
	
	CalculationParameters = ParametersOfCalculationOfDocumentsAccordingToDataOfMutualSettlements(PaymentType_, DocumentsArray);
	
	ResultFromDocuments = CalculationParameters.ResultOfRequestForDocuments;
	
	SelectionByDocument = ResultFromDocuments.Select(QueryResultIteration.ByGroups);
	While SelectionByDocument.Next() Do
		
		DistributeAmountsAccordingToDocumentAccordingToDataOfMutualSettlements(SelectionByDocument, CalculationParameters);

	EndDo;
	
	UpdateDocumentRegisteredRecords_(CalculationParameters.DocumentsToBeRecalculated);
	
EndProcedure

// To distribute the amounts according to the document according to the data of the AR/AP accounts.
// 
// Parameters:
//  SelectionByDocument - QueryResultSelection - Selection By Document
//  DocumentCalculationParameters - See ParametersOfCalculationOfDocumentsAccordingToDataOfMutualSettlements
//
Procedure DistributeAmountsAccordingToDocumentAccordingToDataOfMutualSettlements(SelectionByDocument, DocumentCalculationParameters) Export
	
	ManagementAccountingCurrency = DocumentCalculationParameters.ManagementAccountingCurrency;
	
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	
	SelectionByCalculationObject_ = SelectionByDocument.Select(QueryResultIteration.ByGroups);
	While SelectionByCalculationObject_.Next() Do
		
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(SelectionByCalculationObject_.Organization);
		ContractBasedCourse = SelectionByCalculationObject_.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract;
		
		If ContractBasedCourse And SelectionByDocument.Currency = SelectionByDocument.ARAPCurrency Then
			DocumentExchangeRate = 
				ProcessingOfExchangeRatesTM.GetContractCurrencyExchangeRateFromCache(
					SelectionByCalculationObject_.Contract, 
					SelectionByCalculationObject_.DateOfCourse, 
					DocumentCalculationParameters.ContractExchangeRateCache);
		Else
			DocumentExchangeRate = 
				ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(
					SelectionByDocument.Currency, 
					SelectionByCalculationObject_.DateOfCourse, 
					DocumentCalculationParameters.CurrencyExchangeRateCache,
					LocalAccountingCurrency);
		EndIf;
		
		If ContractBasedCourse Then
			MutualSettlementsExchangeRate = 
				ProcessingOfExchangeRatesTM.GetContractCurrencyExchangeRateFromCache(
					SelectionByCalculationObject_.Contract, 
					SelectionByCalculationObject_.DateOfCourse,
					DocumentCalculationParameters.ContractExchangeRateCache);
		Else
			MutualSettlementsExchangeRate = 
				ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(
					SelectionByDocument.ARAPCurrency, 
					SelectionByCalculationObject_.DateOfCourse,
					DocumentCalculationParameters.CurrencyExchangeRateCache,
					LocalAccountingCurrency);
		EndIf;
		
		If ContractBasedCourse And ManagementAccountingCurrency = SelectionByDocument.ARAPCurrency Then
			ManSExchangeRate = 
				ProcessingOfExchangeRatesTM.GetContractCurrencyExchangeRateFromCache(
					SelectionByCalculationObject_.Contract, 
					SelectionByCalculationObject_.DateOfCourse, 
					DocumentCalculationParameters.ContractExchangeRateCache);
		Else
			ManSExchangeRate = 
				ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(
					ManagementAccountingCurrency,
					SelectionByCalculationObject_.DateOfCourse,
					DocumentCalculationParameters.CurrencyExchangeRateCache,
					LocalAccountingCurrency);
		EndIf;
		
		If ContractBasedCourse 
			And SelectionByDocument.Currency = SelectionByDocument.ARAPCurrency
			And Not SelectionByDocument.ForeignCurrencyTransaction Then
			DocumentCurrencyRateForVATBase = 
				ProcessingOfExchangeRatesTM.GetContractCurrencyExchangeRateFromCache(
					SelectionByCalculationObject_.Contract, 
					SelectionByCalculationObject_.VATBasePeriod, 
					DocumentCalculationParameters.ContractExchangeRateCache);
		Else
			DocumentCurrencyRateForVATBase = 
				ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(
					SelectionByDocument.Currency,
					?(ValueIsFilled(SelectionByCalculationObject_.VATBasePeriod),
						SelectionByCalculationObject_.VATBasePeriod,
						SelectionByCalculationObject_.Period),
					DocumentCalculationParameters.CurrencyExchangeRateCache,
					LocalAccountingCurrency);
		EndIf;
		
		If ContractBasedCourse 
			And Not SelectionByDocument.ForeignCurrencyTransaction Then
			ExchangeRateOfMutualSettlementsForVATBase = 
				ProcessingOfExchangeRatesTM.GetContractCurrencyExchangeRateFromCache(
					SelectionByCalculationObject_.Contract, 
					SelectionByCalculationObject_.VATBasePeriod, 
					DocumentCalculationParameters.ContractExchangeRateCache);
		Else
			ExchangeRateOfMutualSettlementsForVATBase = 
				ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(
					SelectionByDocument.ARAPCurrency,
					SelectionByCalculationObject_.VATBasePeriod,
					DocumentCalculationParameters.CurrencyExchangeRateCache,
					LocalAccountingCurrency);
		EndIf;
		
		CalculationsAmountInCurrency = 0;
		SettlementsPrepaymentInForeignCurrency = 0;
		CalculationsSumOfLocal = 0;
		SettlementsPrepaymentLocal = 0;
		
		CalculationsAmountOfMan = 0;
		CalculationsPrepaymentMan = 0;
		
		CalculationsAmountOfDecreaseInCurrency = 0;
		CalculationsSumOfLocalReduction = 0;
		CalculationsAmountOfManReduction = 0;
		SettlementsPrepaymentDecreaseInCurrency = 0;
		SettlementsPrepaymentReductionLocal = 0;
		
		CalculationsAmountOfIncreaseInCurrency = 0;
		CalculationsSumIncreaseLocal = 0;
		CalculationsAmountOfManIncrease = 0;
		SettlementsPrepaymentIncreaseInCurrency = 0;
		SettlementsPrepaymentIncreaseLocal = 0;
		
		SettlementsPrepaymentInCurrencyBeforeShipment = 0;
		SettlementsLocalPrepaymentBeforeShipment = 0;
		
		LocalConversionRatio = MutualSettlementsExchangeRate;
		ManConversionFactor = MutualSettlementsExchangeRate / ManSExchangeRate;
		
		ForeignCurrencyTransaction      = False;
		VATTaxation = Undefined;
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Recorder",  SelectionByDocument.Ref);
		TheStructureOfTheSearch.Insert("PaymentType_",  SelectionByCalculationObject_.PaymentType_);
		TheStructureOfTheSearch.Insert("ARAPObject",  SelectionByCalculationObject_.ARAPObject);
		ResultOfSearchingForSumsForDistribution = DocumentCalculationParameters.TableOfSumsForDistribution.FindRows(TheStructureOfTheSearch);
		
		If ResultOfSearchingForSumsForDistribution.Count() > 0 Then
			
			AmountsToDistribute = ResultOfSearchingForSumsForDistribution[0];
			
			CalculationsAmountInCurrency = AmountsToDistribute.Debt + AmountsToDistribute.Prepayment;
			SettlementsPrepaymentInForeignCurrency = AmountsToDistribute.Prepayment;
			
			CalculationsSumOfLocal = AmountsToDistribute.DebtLocal + AmountsToDistribute.PrepaymentLocal;
			SettlementsPrepaymentLocal = AmountsToDistribute.PrepaymentLocal;
			
			CalculationsAmountOfMan = AmountsToDistribute.ARAPMan + AmountsToDistribute.PrepaymentMan;
			CalculationsPrepaymentMan = AmountsToDistribute.PrepaymentMan;
			
			CalculationsAmountOfDecreaseInCurrency = 
				?(AmountsToDistribute.Prepayment <= 0, AmountsToDistribute.Prepayment, 0)
				+ ?(AmountsToDistribute.Debt <= 0, AmountsToDistribute.Debt, 0);
			CalculationsSumOfLocalReduction = 
				?(AmountsToDistribute.Prepayment <= 0, AmountsToDistribute.PrepaymentLocal, 0)
				+ ?(AmountsToDistribute.Debt <= 0, AmountsToDistribute.DebtLocal, 0);
			CalculationsAmountOfManReduction =
				?(AmountsToDistribute.Prepayment <= 0, AmountsToDistribute.PrepaymentMan, 0)
				+ ?(AmountsToDistribute.Debt <= 0, AmountsToDistribute.ARAPMan, 0);
			SettlementsPrepaymentDecreaseInCurrency = 
				?(AmountsToDistribute.Prepayment <= 0, AmountsToDistribute.Prepayment, 0);
			SettlementsPrepaymentReductionLocal = 
				?(AmountsToDistribute.Prepayment <= 0, AmountsToDistribute.PrepaymentLocal, 0);
			
			CalculationsAmountOfIncreaseInCurrency = 
				?(AmountsToDistribute.Prepayment >= 0, AmountsToDistribute.Prepayment, 0)
				+ ?(AmountsToDistribute.Debt >= 0, AmountsToDistribute.Debt, 0);
			CalculationsSumIncreaseLocal = 
				?(AmountsToDistribute.Prepayment >= 0, AmountsToDistribute.PrepaymentLocal, 0)
				+ ?(AmountsToDistribute.Debt >= 0, AmountsToDistribute.DebtLocal, 0);
			CalculationsAmountOfManIncrease =
				?(AmountsToDistribute.Prepayment >= 0, AmountsToDistribute.PrepaymentMan, 0)
				+ ?(AmountsToDistribute.Debt >= 0, AmountsToDistribute.ARAPMan, 0);
			SettlementsPrepaymentIncreaseInCurrency = 
				?(AmountsToDistribute.Prepayment >= 0, AmountsToDistribute.Prepayment, 0);
			SettlementsPrepaymentIncreaseLocal = 
				?(AmountsToDistribute.Prepayment >= 0, AmountsToDistribute.PrepaymentLocal, 0);
			
			SettlementsPrepaymentInCurrencyBeforeShipment = 
				?(AmountsToDistribute.PrepaymentBeforeShipment >= 0, AmountsToDistribute.PrepaymentBeforeShipment, 0);
			SettlementsLocalPrepaymentBeforeShipment = 
				?(AmountsToDistribute.PrepaymentBeforeShipment >= 0, AmountsToDistribute.LocalPrepaymentBeforeShipment, 0);
			
			ForeignCurrencyTransaction  = ?(AmountsToDistribute.ForeignCurrencyTransaction = NULL, False, AmountsToDistribute.ForeignCurrencyTransaction);
			VATTaxation = ?(AmountsToDistribute.VATTaxation = NULL, Undefined, AmountsToDistribute.VATTaxation);
			
			If NewOnlineARAPAccounting Then
				// We do not check the denominator, as an exception is required in case of incorrect RegisteredRecorded
				LocalConversionRatio = AmountsToDistribute.NumeratorLocal/AmountsToDistribute.LocalDenominator;
				ManConversionFactor = AmountsToDistribute.NumeratorMan/AmountsToDistribute.DenominatorOfMan;
			Else
				LocalConversionRatio = ?(
					AmountsToDistribute.LocalDenominator = 0,
					0,
					AmountsToDistribute.NumeratorLocal/AmountsToDistribute.LocalDenominator);
				ManConversionFactor = ?(
					AmountsToDistribute.DenominatorOfMan = 0,
					0,
					AmountsToDistribute.NumeratorMan/AmountsToDistribute.DenominatorOfMan);
			EndIf;
			
		EndIf;
		
		If SelectionByCalculationObject_.AmountOfSettlementsToRecalculate <> CalculationsAmountInCurrency Then
			CalculationsSumOfLocal = 
				SettlementsPrepaymentLocal 
				+ Round(SelectionByCalculationObject_.AmountOfSettlementsToRecalculate * MutualSettlementsExchangeRate, 2) 
				- Round(SettlementsPrepaymentInForeignCurrency * MutualSettlementsExchangeRate, 2);
				
			CalculationsAmountOfMan = 
				CalculationsPrepaymentMan 
				+ Round(SelectionByCalculationObject_.AmountOfSettlementsToRecalculate * MutualSettlementsExchangeRate / ManSExchangeRate, 2) 
				- Round(SettlementsPrepaymentInForeignCurrency * MutualSettlementsExchangeRate / ManSExchangeRate, 2);
		EndIf;
		
		SelectionByRecordType = SelectionByCalculationObject_.Select(QueryResultIteration.ByGroups);
		While SelectionByRecordType.Next() Do
			
			AmountIncludingVAT      = SelectionByRecordType.AmountIncludingVAT;
			AmountARAP = SelectionByRecordType.AmountOfSettlementsToRecalculate;
			
			If SelectionByRecordType.ThisIsReverseTransaction And AmountARAP = CalculationsAmountOfDecreaseInCurrency Then
				LocalSumForDistribution = CalculationsSumOfLocalReduction;
				AmountOfManToDistribute = CalculationsAmountOfManReduction;
			ElsIf Not SelectionByRecordType.ThisIsReverseTransaction And AmountARAP = CalculationsAmountOfIncreaseInCurrency Then
				LocalSumForDistribution = CalculationsSumIncreaseLocal;
				AmountOfManToDistribute = CalculationsAmountOfManIncrease;
			ElsIf SelectionByCalculationObject_.AmountOfSettlementsToRecalculate = CalculationsAmountInCurrency Then
				// The total amount of the document and the amount in the settlement registers are the same.
				// At the same time, there are lines of the document to increase and decrease.
				LocalSumForDistribution = Round(AmountARAP * LocalConversionRatio, 2);
				LocalDifference = 
					LocalSumForDistribution 
					+ Round((SelectionByCalculationObject_.AmountOfSettlementsToRecalculate - AmountARAP) * LocalConversionRatio, 2)
					- CalculationsSumOfLocal;
				If (LocalDifference < 0 And SelectionByRecordType.ThisIsReverseTransaction) Or (LocalDifference > 0 And Not SelectionByRecordType.ThisIsReverseTransaction) Then
					LocalSumForDistribution = LocalSumForDistribution - LocalDifference;
				EndIf;
				
				AmountOfManToDistribute = Round(AmountARAP * ManConversionFactor, 2);
				ManSDifference = 
					AmountOfManToDistribute 
					+ Round((SelectionByCalculationObject_.AmountOfSettlementsToRecalculate - AmountARAP) * ManConversionFactor, 2)
					- CalculationsAmountOfMan;
				If (ManSDifference < 0 And SelectionByRecordType.ThisIsReverseTransaction) Or (ManSDifference > 0 And Not SelectionByRecordType.ThisIsReverseTransaction) Then
					AmountOfManToDistribute = AmountOfManToDistribute - ManSDifference;
				EndIf;
			Else
				// The amount in the settlement registers does not match the total amount of the document.
				// For example, the implementation is in the Status of "In transit".
				LocalSumForDistribution = CalculationsSumOfLocal;
				AmountOfManToDistribute = CalculationsAmountOfMan;	
			EndIf;
			
			If SelectionByRecordType.ThisIsAcquisitionAdjustment 
				Or SelectionByRecordType.ThisIsImplementationAdjustment Then
				
				// The VAT adjustment rate must correspond to the VAT reflection rate of the foundation document.
				VATRateAdjustments = DocumentCurrencyRateForVATBase;
				RowOfTableOfRatesOfVATAdjustments = DocumentCalculationParameters.VATAdjustmentRates.Find(SelectionByRecordType.Ref, "Ref");
				If RowOfTableOfRatesOfVATAdjustments <> Undefined
					And RowOfTableOfRatesOfVATAdjustments.VATRateAdjustments <> Undefined Then
					VATRateAdjustments = RowOfTableOfRatesOfVATAdjustments.VATRateAdjustments;
				EndIf;
				
				DatabaseWithVATLocalByDocument = Round(AmountIncludingVAT * VATRateAdjustments, 2);
				
			ElsIf SelectionByRecordType.ThisIsImplementationWithDeferredTransferOfOwnership Then
				DatabaseWithVATLocalByDocument = 
					SettlementsLocalPrepaymentBeforeShipment + Round((AmountARAP - SettlementsPrepaymentInCurrencyBeforeShipment) * ExchangeRateOfMutualSettlementsForVATBase, 2);
			Else
				DatabaseWithVATLocalByDocument = LocalSumForDistribution;	
			EndIf;
			
			ConsideredDistributionBases = 0;
			AlreadyDistributedLocal = 0;
			AlreadyDistributedMan = 0;
			AlreadyAllocatedAmountForVATBase = 0;
			
			ExchangeRateOfManTakingIntoAccountCreditedAdvances = ManSExchangeRate;
			If AmountOfManToDistribute <> 0 Then
				ExchangeRateOfManTakingIntoAccountCreditedAdvances = LocalSumForDistribution / AmountOfManToDistribute;
			EndIf;
			
			Selection = SelectionByRecordType.Select();
			While Selection.Next() Do
				
				Record = DocumentCalculationParameters.DocumentAmountTable.Add();
				FillPropertyValues(Record, Selection);
				
				If Not Selection.RecalculateAmounts Then
					Continue;
				EndIf;
				
				SumWithVATLine = Selection.AmountExcludingVAT + Selection.VATAmount;
				
				Record.AmountIncludingVATCompl = Round(LocalSumForDistribution * (ConsideredDistributionBases + SumWithVATLine) / AmountIncludingVAT, 2) - AlreadyDistributedLocal;
				Record.AmountIncludingVATMan  = Round(AmountOfManToDistribute * (ConsideredDistributionBases + SumWithVATLine) / AmountIncludingVAT, 2) - AlreadyDistributedMan;
				Record.AmountForVATBase  = Round(DatabaseWithVATLocalByDocument * (ConsideredDistributionBases + SumWithVATLine) / AmountIncludingVAT, 2) - AlreadyAllocatedAmountForVATBase;
				
				ConsideredDistributionBases = ConsideredDistributionBases + SumWithVATLine;
				AlreadyDistributedLocal     = AlreadyDistributedLocal + Record.AmountIncludingVATCompl;
				AlreadyDistributedMan      = AlreadyDistributedMan + Record.AmountIncludingVATMan;
				AlreadyAllocatedAmountForVATBase = AlreadyAllocatedAmountForVATBase + Record.AmountForVATBase; 
				
				If (SelectionByDocument.ARAPCurrency = LocalAccountingCurrency
					 Or SelectionByDocument.Currency = LocalAccountingCurrency)
					 And ((SelectionByRecordType.AmountExcludingVATCompl + SelectionByRecordType.VATAmountCompl) = LocalSumForDistribution) Then
					RecalculateLocal = False;
				Else
					RecalculateLocal = True;
				EndIf;
				
				If (SelectionByDocument.ARAPCurrency = ManagementAccountingCurrency
					 Or SelectionByDocument.Currency = ManagementAccountingCurrency)
					 And ((SelectionByRecordType.AmountExcludingVATMan + SelectionByRecordType.VATAmountMan) = AmountOfManToDistribute) Then
					RecalculateMan = False;
				Else
					RecalculateMan = True;
				EndIf;
				
				If RecalculateLocal Then
					If ValueIsFilled(Record.VATRate) Then
						// Calculate VAT and amounts without VAT in the currency of the regl. and upr. accounting
						If VATTaxation = Enums.VATTaxationTypes.DigitalServices Then
							
							If Not Selection.DoNotRecalculateVATAmounts Then
								
								// For electronic services, the base is the total amount.
								// VAT is calculated from the total amount, at the estimated rate.
								Record.VATBaseLocal = (Record.AmountExcludingVAT + Record.VATAmount) * DocumentExchangeRate;
								If Record.VATAmount = 0 Then 
									Record.VATAmountCompl = 0;
								Else
									Record.VATAmountCompl = PriceManagementSystemClientServer.CalculateVATAmount(Record.VATBaseLocal, Selection.VATRate, False);
								EndIf;
								
							EndIf;
						
						ElsIf ForeignCurrencyTransaction Then
							
							If Not Selection.DoNotRecalculateVATAmounts Then
								
								// The VAT base is calculated at the exchange rate on the date of the document
								Record.VATBaseLocal = Record.AmountExcludingVAT * DocumentCurrencyRateForVATBase;
								If Record.VATAmount = 0 Then 
									Record.VATAmountCompl = 0;
								Else
									Record.VATAmountCompl = PriceManagementSystemClientServer.CalculateVATAmount(Record.VATBaseLocal, Selection.VATRate, False);
								EndIf;
								
							EndIf;
							
						Else
							// Calculation of the VAT base according to mutual settlements (taking into account the credited prepayments)
							
							If Not Selection.DoNotRecalculateVATAmounts Then
								
								If Record.VATAmount = 0 Then 
									Record.VATAmountCompl = 0;
								Else
									Record.VATAmountCompl = PriceManagementSystemClientServer.CalculateVATAmount(Record.AmountForVATBase, Record.VATRate);
								EndIf;
								Record.VATBaseLocal = Record.AmountForVATBase - Record.VATAmountCompl;
							EndIf;
							
						EndIf;
					EndIf;
					Record.AmountExcludingVATCompl = Record.AmountIncludingVATCompl - Record.VATAmountCompl;
				EndIf;
				
				If Not Selection.DoNotRecalculateVATAmounts Then
					
					If RecalculateMan
						Or RecalculateLocal Then
							
						If Record.AmountExcludingVAT = 0 Then
							
							Record.VATAmountMan = Record.AmountIncludingVATMan;
							
						Else
							
							Record.VATAmountMan = ?(ExchangeRateOfManTakingIntoAccountCreditedAdvances = 0,
								0,
								Record.VATAmountCompl / ExchangeRateOfManTakingIntoAccountCreditedAdvances);
							
						EndIf;
						
					EndIf;
					
				EndIf;
				
				If RecalculateMan
					Or RecalculateLocal Then
						
					If Record.AmountExcludingVAT = 0 Then
						Record.AmountExcludingVATMan = 0;
					Else
						Record.AmountExcludingVATMan = Record.AmountIncludingVATMan - Record.VATAmountMan;
					EndIf;
					
				EndIf;
				
			EndDo;
		EndDo;
	EndDo;
	
	ListDocumentAmounts(DocumentCalculationParameters.DataOfPaymentSchedule,
		DocumentCalculationParameters.DocumentAmountTable, DocumentCalculationParameters.CurrencyExchangeRateCache,
		DocumentCalculationParameters.ContractExchangeRateCache, SelectionByDocument.Ref);
	RecordRegisteredRecordsInInterestExpenseDiscounting(DocumentCalculationParameters.DataOfPaymentSchedule,
		SelectionByDocument.Ref);
				
	RecordSet = InformationRegisters.DocumentAmountsInAccountingCurrency.CreateRecordSet();
	RecordSet.Filter.Recorder.Set(SelectionByDocument.Ref);
	RecordSet.Load(DocumentCalculationParameters.DocumentAmountTable);
	RecordSet.AdditionalProperties.Insert("UpdateDocumentAmountsInAccountingCurrencies");
	RecordSet.Write();
		
	DocumentCalculationParameters.DocumentAmountTable.Clear();

EndProcedure

//	Request for documents for which the amounts in accounting currencies do not match the settlement data.
//
//	Returns:
//		String - query text.
Function TextOfRequestForDocumentsToBeRecalculated() Export
	
	ArrayOfRequestTexts = New Array();
	ArrayOfRequestTexts.Add(RequestTextForSettlementAmounts("TTSettlementAmounts"));
	ArrayOfRequestTexts.Add(TextOfRequestToCompareDocumentsForRecalculation());
	
	Return StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	
EndFunction

// Parameters for calculating documents based on settlement data.
// 
// Parameters:
//  PaymentType_ - String - Type of Calculations
//  DocumentsArray - Array of DocumentRef - array of documents
// 
// Returns:
//  Structure - Parameters Of Calculation Of Documents According To Data Of Mutual Settlements:
// * ResultOfRequestForDocuments - QueryResult - Result Of A Request For Documents
// * DocumentsToBeRecalculated - Array of DocumentRef - Documents To Be Recalculated
// * TableOfSumsForDistribution - See DocumentSumsForLineDistribution 
// * VATAdjustmentRates - ValueTable - Table of VAT adjustment rates:
// ** Ref - DocumentRef - link to the document
// ** VATRateAdjustments - Number - Course value
// * DocumentAmountTable - ValueTable - The structure of the register of information "SummyDocumentovVAlutahuCheta":
// ** AmountIncludingVATCompl  - Number
// ** AmountIncludingVATMan - Number
// ** AmountForVATBase - Number
// * DataOfPaymentSchedule - See PaymentSchedulesForDiscounting
// * CurrencyExchangeRateCache - See ProcessingOfExchangeRatesTM.InitializeCurrencyExchangeRateCache
// * ContractExchangeRateCache - See ProcessingOfExchangeRatesTM.InitializeCacheOfContractExchangeRates
// * ManagementAccountingCurrency - CatalogRef.Currencies, Arbitrary - 
//
Function ParametersOfCalculationOfDocumentsAccordingToDataOfMutualSettlements(PaymentType_, DocumentsArray) Export
	
	Query = New Query();
	Query.Text = 
	"SELECT DISTINCT
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.Period AS Period,
	|	CASE 
	|		WHEN VALUETYPE(RegisterData.Recorder) = TYPE(Document.PurchaseAdjustment)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsAcquisitionAdjustment,
	|	CASE 
	|		WHEN VALUETYPE(RegisterData.Recorder) = TYPE(Document.SaleAdjustment)
	|			THEN TRUE 
	|		ELSE FALSE
	|	END AS ThisIsImplementationAdjustment,
	|	CASE 
	|		WHEN VALUETYPE(RegisterData.Recorder) = TYPE(Document.SaleAdjustment)
	|			THEN CAST(RegisterData.Recorder AS Document.SaleAdjustment).DocumentBasis 
	|		WHEN VALUETYPE(RegisterData.Recorder) = TYPE(Document.PurchaseAdjustment)
	|			THEN CAST(RegisterData.Recorder AS Document.PurchaseAdjustment).DocumentBasis
	|		ELSE UNDEFINED
	|	END AS BasisOfAdjustment,    
	|	CASE 
	|		WHEN VALUETYPE(RegisterData.Recorder) = TYPE(Document.CustomerInvoice)
	|			 AND CAST(RegisterData.Recorder AS Document.CustomerInvoice).BusinessOperation IN (
	|							VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|							VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|			THEN TRUE 
	|		WHEN VALUETYPE(RegisterData.Recorder) = TYPE(Document.CustomerInvoiceServicesAndAssets)
	|			 AND CAST(RegisterData.Recorder AS Document.CustomerInvoiceServicesAndAssets).BusinessOperation IN (
	|							VALUE(Enum.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer))			
	|			THEN TRUE 
	|		ELSE FALSE
	|	END AS ThisIsImplementationWithDeferredTransferOfOwnership,
	|	CASE 
	|		WHEN VALUETYPE(RegisterData.Recorder) = TYPE(Document.VendorInvoice)
	|				AND VendorInvoice.DocumentExchangeRateDate <> DATETIME(1, 1, 1)
	|			THEN VendorInvoice.DocumentExchangeRateDate
	|		WHEN VALUETYPE(RegisterData.Recorder) = TYPE(Document.VendorInvoiceServicesAndAssets)
	|				AND VendorInvoiceServicesAndAssets.DocumentExchangeRateDate <> DATETIME(1, 1, 1)
	|			THEN VendorInvoiceServicesAndAssets.DocumentExchangeRateDate
	|		ELSE RegisterData.Period 
	|	END AS DateOfCourse
	|INTO DocumentsTable
	|FROM
	|	InformationRegister.DocumentAmountsInAccountingCurrency AS RegisterData
	|		LEFT JOIN Document.VendorInvoice AS VendorInvoice
	|		ON RegisterData.Recorder = VendorInvoice.Ref
	|		LEFT JOIN Document.VendorInvoiceServicesAndAssets AS VendorInvoiceServicesAndAssets
	|		ON RegisterData.Recorder = VendorInvoiceServicesAndAssets.Ref
	|
	|WHERE
	|	RegisterData.PaymentType_ = &PaymentType_
	|	AND RegisterData.RecalculateBasedOnARAPData
	|	AND (RegisterData.Currency <> RegisterData.ARAPObject.Organization.LocalAccountingCurrency
	|		AND RegisterData.ARAPCurrency <> RegisterData.ARAPObject.Organization.LocalAccountingCurrency
	|		OR RegisterData.Currency <> &ManagementAccountingCurrency
	|			AND RegisterData.ARAPCurrency <> &ManagementAccountingCurrency)
	|	AND RegisterData.Recorder IN (&DocumentsArray)
	|
	|INDEX BY
	|	Recorder,
	|	Period
	|;
	|
	////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RegisterData.Recorder AS Ref,
	|	RegisterData.Active AS Active,
	|	RegisterData.Period AS Period,
	|	RegisterData.RowID AS RowID,
	|
	|	RegisterData.AmountExcludingVAT          AS AmountExcludingVAT,
	|	RegisterData.VATAmount             AS VATAmount,
	|	RegisterData.AmountExcludingVATCompl      AS AmountExcludingVATCompl,
	|	RegisterData.VATAmountCompl         AS VATAmountCompl,
	|	RegisterData.VATBaseLocal          AS VATBaseLocal,
	|	RegisterData.AmountExcludingVATMan       AS AmountExcludingVATMan,
	|	RegisterData.VATAmountMan          AS VATAmountMan,
	|	RegisterData.AmountARAP  AS AmountARAP,
	|	RegisterData.AmountVATARAP AS AmountVATARAP,
	|
	|	RegisterData.Currency                     AS Currency,
	|	RegisterData.ARAPCurrency       AS ARAPCurrency,
	|	RegisterData.VATRate                  AS VATRate,
	|	RegisterData.PaymentType_                AS PaymentType_,
	|	RegisterData.ARAPObject             AS ARAPObject,
	|	ARAPObjects.Organization               AS Organization,
	|	ARAPObjects.Contract                   AS Contract,
	|	ARAPObjects.ForeignCurrencyTransaction             AS ForeignCurrencyTransaction,
	|	ISNULL(
	|		ARAPObjects.Contract.ContractRateOption, 
	|		VALUE(Enum.ContractRateOptions.Mutable)) AS ContractRateOption,
	|	RegisterData.VATBasePeriod              AS VATBasePeriod,
	|	DocumentsTable.DateOfCourse               AS DateOfCourse,
	|	RegisterData.RecordedInARAPAccounting        AS RecordedInARAPAccounting,
	|	RegisterData.RecalculateBasedOnARAPData AS RecalculateBasedOnARAPData,
	|	RegisterData.DoNotRecalculateVATAmounts    AS DoNotRecalculateVATAmounts,
	|	CASE
	|		WHEN RegisterData.PaymentType_ = &PaymentType_
	|			AND (RegisterData.AmountExcludingVAT + RegisterData.VATAmount) <> 0
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS RecalculateAmounts,
	|
	|	CASE WHEN RegisterData.PaymentType_ = &PaymentType_
	|		THEN RegisterData.AmountExcludingVAT + RegisterData.VATAmount
	|		ELSE 0
	|	END AS AmountIncludingVAT,
	|
	|	CASE WHEN RegisterData.PaymentType_ = &PaymentType_
	|		THEN RegisterData.AmountARAP
	|		ELSE 0
	|	END AS AmountOfSettlementsToRecalculate,
	|	
	|	DocumentsTable.ThisIsAcquisitionAdjustment AS ThisIsAcquisitionAdjustment,
	|	DocumentsTable.ThisIsImplementationAdjustment AS ThisIsImplementationAdjustment,
	|	DocumentsTable.ThisIsImplementationWithDeferredTransferOfOwnership AS ThisIsImplementationWithDeferredTransferOfOwnership,  
	|
	|	CASE WHEN RegisterData.AmountExcludingVAT + RegisterData.VATAmount < 0
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsReverseTransaction
	|
	|FROM
	|	InformationRegister.DocumentAmountsInAccountingCurrency AS RegisterData
	|		INNER JOIN DocumentsTable AS DocumentsTable
	|		ON RegisterData.Recorder = DocumentsTable.Recorder
	|			AND RegisterData.Period = DocumentsTable.Period
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON RegisterData.ARAPObject = ARAPObjects.Ref
	|	
	|ORDER BY 
	|	ThisIsAcquisitionAdjustment 
	|
	|TOTALS
	|	MAX(Period),
	|	SUM(AmountIncludingVAT),
	|	SUM(AmountExcludingVATCompl),
	|	SUM(VATAmountCompl),
	|	SUM(AmountExcludingVATMan),
	|	SUM(VATAmountMan),
	|	SUM(AmountOfSettlementsToRecalculate),
	|	MAX(ARAPCurrency),
	|	MAX(Currency),
	|	MAX(PaymentType_),
	|	MAX(VATBasePeriod),
	|	MAX(DateOfCourse),
	|	MAX(ThisIsAcquisitionAdjustment),
	|	MAX(ThisIsImplementationAdjustment), 
	|	MAX(ThisIsImplementationWithDeferredTransferOfOwnership), 	
	|	MAX(Organization),
	|	MAX(Contract),
	|	MAX(ForeignCurrencyTransaction),
	|	MAX(ContractRateOption)
	|BY
	|	RegisterData.Recorder AS REFS,
	|	RegisterData.ARAPObject AS ARAPObject,
	|	CASE WHEN RegisterData.AmountExcludingVAT + RegisterData.VATAmount < 0
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsReverseTransaction
	|;
	|
	|///////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsTable.Recorder AS Recorder
	|FROM
	|	DocumentsTable AS DocumentsTable
	|
	|ORDER BY 
	|	DocumentsTable.Period
	|;
	|
	|///////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsTable.Recorder AS Ref,
	|	CASE
	|		WHEN SUM(DocumentAmountsInAccountingCurrency.AmountExcludingVAT + DocumentAmountsInAccountingCurrency.VATAmount) <> 0
	|			THEN SUM(DocumentAmountsInAccountingCurrency.VATBaseLocal + DocumentAmountsInAccountingCurrency.VATAmountCompl) 
	|					/ SUM(DocumentAmountsInAccountingCurrency.AmountExcludingVAT + DocumentAmountsInAccountingCurrency.VATAmount) 
	|		ELSE UNDEFINED
	|	END AS VATRateAdjustments
	|FROM
	|	DocumentsTable AS DocumentsTable
	|	LEFT JOIN
	|		InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
	|	ON
	|		DocumentsTable.BasisOfAdjustment = DocumentAmountsInAccountingCurrency.Recorder
	|WHERE
	|	(DocumentsTable.ThisIsAcquisitionAdjustment OR DocumentsTable.ThisIsImplementationAdjustment)
	|	AND NOT DocumentsTable.BasisOfAdjustment REFS Document.SourceDocument
	|
	|GROUP BY
	|	DocumentsTable.Recorder
	|
	|UNION
	|
	|SELECT
	|	DocumentsTable.Recorder AS Ref,
	|	CASE
	|		WHEN SourceDocument.DocumentAmount <> 0
	|			THEN SourceDocument.SumCompl
	|					/ SourceDocument.DocumentAmount
	|		ELSE 0
	|	END AS VATRateAdjustments
	|FROM
	|	DocumentsTable AS DocumentsTable
	|	INNER JOIN
	|		Document.SourceDocument AS SourceDocument
	|	ON
	|		DocumentsTable.BasisOfAdjustment = SourceDocument.Ref
	|WHERE
	|	DocumentsTable.BasisOfAdjustment REFS Document.SourceDocument
	|";
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	Query.SetParameter("ManagementAccountingCurrency", ManagementAccountingCurrency);
	
	Query.SetParameter("PaymentType_", 
		?(PaymentType_ = "CustomersARAPAccounting",
		Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting,
		Enums.PartnersARAPAccountingTypes.VendorARAPAccounting));
		
	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	ResultFromDocuments = ResultsArray[1]; // QueryResult - 
	DocumentsToBeRecalculated   = ResultsArray[2].Unload().UnloadColumn("Recorder");
	TableOfSumsForDistribution = DocumentSumsForLineDistribution(DocumentsToBeRecalculated);
	TableOfSumsForDistribution.Indexes.Add("Recorder, ARAPObject, PaymentType_");
	
	VATAdjustmentRates = ResultsArray[3].Unload();
	VATAdjustmentRates.Indexes.Add("Ref");
	
	DocumentAmountTable = InformationRegisters.DocumentAmountsInAccountingCurrency.CreateRecordSet().UnloadColumns();
	DocumentAmountTable.Columns.Add("AmountIncludingVATCompl", TMCommonUse.MoneyFieldTypeDescription());
	DocumentAmountTable.Columns.Add("AmountIncludingVATMan", TMCommonUse.MoneyFieldTypeDescription());
	DocumentAmountTable.Columns.Add("AmountForVATBase", TMCommonUse.MoneyFieldTypeDescription());
	
	DataOfPaymentSchedule = PaymentSchedulesForDiscounting(DocumentsArray, PaymentType_);
	
	CurrencyExchangeRateCache = ProcessingOfExchangeRatesTM.InitializeCurrencyExchangeRateCache();
	ContractExchangeRateCache = ProcessingOfExchangeRatesTM.InitializeCacheOfContractExchangeRates();
	
	DataForCalculation = New Structure;
	DataForCalculation.Insert("ResultOfRequestForDocuments", ResultFromDocuments);
	DataForCalculation.Insert("DocumentsToBeRecalculated", DocumentsToBeRecalculated);
	DataForCalculation.Insert("TableOfSumsForDistribution", TableOfSumsForDistribution);
	DataForCalculation.Insert("VATAdjustmentRates", VATAdjustmentRates);
	DataForCalculation.Insert("DocumentAmountTable", DocumentAmountTable);
	DataForCalculation.Insert("DataOfPaymentSchedule", DataOfPaymentSchedule);
	DataForCalculation.Insert("CurrencyExchangeRateCache", CurrencyExchangeRateCache);
	DataForCalculation.Insert("ContractExchangeRateCache", ContractExchangeRateCache);
	DataForCalculation.Insert("ManagementAccountingCurrency", ManagementAccountingCurrency);
	
	Return DataForCalculation;
	
EndFunction

#Region BackdateJobQueue

// Data for the formation of tasks for non-operational document verification.
// Called when writing a set of register entries.
// 
// Parameters:
//  RecordSet - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records.
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of types of tasks.
//                According to this list, new tasks must be registered according to the recorded register data.
//  TempTablesManager - TempTablesManager - When specifying the MW, the data from the temporary tables will be used when creating new tasks.
//  DataForRegisteringTasks - Undefined, ValueTable - A table with data for registering new tasks.
// 
// Returns:
//  ValueTable - Data For The Formation Of Tasks For Non-Operational Document Verification:
// * Organization - CatalogRef.Companies - The organization for which the new task will be generated.
// * TaskPeriod  - Date - The task period. Coincides with the period of the recorded data in the register.
// * Document - DocumentRef - Link to the document for which the task will be registered.
// * JobKind - CatalogRef.BackdateJobKinds - Type of registered task.
//
Function DataForFormationOfTasksForNonOperationalDocumentVerification(RecordSet, KindsOfTasks,
	TempTablesManager, DataForRegisteringTasks = Undefined) Export

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = "
	|SELECT DISTINCT
	|	DataForProcessing_.Period AS TaskPeriod,
	|	DataForProcessing_.Recorder AS Document,
	|	DocumentsRegistry.Organization AS Organization
	|FROM
	|	QueueDataForAdditionalDocuments AS DataForProcessing_
	|		INNER JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON DocumentsRegistry.Ref = DataForProcessing_.Recorder
	|WHERE
	|	DocumentsRegistry.Organization <> VALUE(Catalog.Companies.EmptyRef)";
	
	DataForCreatingTasks = Query.Execute().Unload();
	
	
	TypesOfRegistrarsReflectionOfDocumentsInInternationalAccounting = Metadata.InformationRegisters.DocumentPostingInFinancialAccounting.StandardAttributes.Recorder.Type;
	DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();
	
	For Each CurrentTypeOfTask In KindsOfTasks Do

		
		If CurrentTypeOfTask = Catalogs.BackdateJobKinds.RecordInFinancialAccounting Then
			TableOfDocumentsToBeReflected = InformationRegisters.DocumentPostingInFinancialAccounting.TableOfDocumentsToBeReflectedInInternationalAccounting();
			For Each CurrentData In DataForCreatingTasks Do
				If TypesOfRegistrarsReflectionOfDocumentsInInternationalAccounting.ContainsType(TypeOf(CurrentData.Document)) Then
					NewRow = TableOfDocumentsToBeReflected.Add();
					FillPropertyValues(NewRow, CurrentData);
					NewRow.DateRecord = BegOfDay(CurrentData.TaskPeriod);
					NewRow.Period = BegOfDay(CurrentData.TaskPeriod);
				EndIf;
			EndDo;
			TableOfDocumentsToBeReflected.GroupBy("Document, Organization, DateRecord, Period");
			Return TableOfDocumentsToBeReflected;
		EndIf;
		If RecordSet.AdditionalProperties.Property("UpdateDocumentAmountsInAccountingCurrencies")
			And CurrentTypeOfTask = Catalogs.BackdateJobKinds.UpdateDocumentAmountsInAccountingCurrencies Then
			Continue;
		EndIf;
		
		For Each CurrentData In DataForCreatingTasks Do
			NewRow = DataTable.Add();
			FillPropertyValues(NewRow, CurrentData);
			NewRow.JobKind = CurrentTypeOfTask;
		EndDo;
		
	EndDo;
	
	Return DataTable;
	
EndFunction

// Performs a condition check and starts the execution of non-operational queue tasks in the document execution transaction.
// 
// Parameters:
//  Document - DocumentObject - current document
Procedure CheckToCompleteTasksInNonOperationalQueue(Document) Export
	
	If ToCalculateAmountsInTransactionOfDocument(Document) Then
		BackdateJobQueue.CompleteTasksOfNonOperationalQueueInDocumentTransaction(Document.Ref,
			Catalogs.BackdateJobKinds.UpdateFinancialRegistersRecords);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function TextOfRequestToCompareDocumentsForRecalculation()
	
	ComparisonText = "
	|SELECT
	|	NestedQuery.DocumentRecorder               AS ARAPDocument,
	|	NestedQuery.PaymentType_                       AS PaymentType_,
	|	NestedQuery.ARAPObject                    AS ARAPObject,
	|	SUM(NestedQuery.SumIncreaseLocalCalculations) AS SumIncreaseLocalCalculations,
	|	SUM(NestedQuery.AmountOfManIncreaseCalculations)  AS AmountOfManIncreaseCalculations,
	|	SUM(NestedQuery.SumReductionLocalCalculations) AS SumReductionLocalCalculations,
	|	SUM(NestedQuery.AmountOfManReductionCalculations)  AS AmountOfManReductionCalculations,
	|	SUM(NestedQuery.AmountOfLocalIncrease)        AS AmountOfLocalIncrease,
	|	SUM(NestedQuery.AmountOfManIncrease)         AS AmountOfManIncrease,
	|	SUM(NestedQuery.AmountOfLocalReduction)        AS AmountOfLocalReduction,
	|	SUM(NestedQuery.AmountOfManReduction)         AS AmountOfManReduction
	|FROM
	|	(SELECT
	|		SettlementsAmounts.PaymentType_                    AS PaymentType_,
	|		SettlementsAmounts.Recorder                    AS DocumentRecorder,
	|		SettlementsAmounts.ARAPObject                 AS ARAPObject,
	|		CASE 
	|			WHEN NOT SettlementsAmounts.UnfoldedRegisteredRecordsArePossible AND SettlementsAmounts.PrepaymentLocal + SettlementsAmounts.DebtLocal > 0
	|				THEN CASE 
	|						WHEN SettlementsAmounts.PrepaymentLocal + SettlementsAmounts.DebtLocal > 0
	|							THEN SettlementsAmounts.PrepaymentLocal + SettlementsAmounts.DebtLocal
	|						ELSE 0
	|					END
	|			ELSE CASE
	|						WHEN SettlementsAmounts.PrepaymentLocal > 0 
	|							THEN SettlementsAmounts.PrepaymentLocal 
	|						ELSE 0 
	|					END 
	|				+ CASE 
	|						WHEN SettlementsAmounts.DebtLocal > 0
	|							THEN SettlementsAmounts.DebtLocal 
	|						ELSE 0 
	|					END
	|		END                                             AS SumIncreaseLocalCalculations,
	|		CASE 
	|			WHEN NOT SettlementsAmounts.UnfoldedRegisteredRecordsArePossible
	|				THEN CASE 
	|						WHEN SettlementsAmounts.PrepaymentMan + SettlementsAmounts.ARAPMan > 0
	|							THEN SettlementsAmounts.PrepaymentMan + SettlementsAmounts.ARAPMan
	|						ELSE 0
	|					END
	|			ELSE CASE
	|						WHEN SettlementsAmounts.PrepaymentMan > 0 
	|							THEN SettlementsAmounts.PrepaymentMan 
	|						ELSE 0 
	|					END 
	|				+ CASE 
	|						WHEN SettlementsAmounts.ARAPMan > 0
	|							THEN SettlementsAmounts.ARAPMan 
	|						ELSE 0 
	|					END
	|		END                                             AS AmountOfManIncreaseCalculations,
	|		CASE 
	|			WHEN NOT SettlementsAmounts.UnfoldedRegisteredRecordsArePossible
	|				THEN CASE 
	|						WHEN  SettlementsAmounts.PrepaymentLocal + SettlementsAmounts.DebtLocal < 0 
	|							THEN SettlementsAmounts.PrepaymentLocal + SettlementsAmounts.DebtLocal
	|						ELSE 0
	|					END
	|			ELSE CASE
	|						WHEN SettlementsAmounts.PrepaymentLocal < 0 
	|							THEN SettlementsAmounts.PrepaymentLocal 
	|						ELSE 0 
	|					END 
	|				+ CASE 
	|						WHEN SettlementsAmounts.DebtLocal < 0
	|							THEN SettlementsAmounts.DebtLocal 
	|						ELSE 0 
	|					END
	|		END                                             AS SumReductionLocalCalculations,
	|		CASE 
	|			WHEN NOT SettlementsAmounts.UnfoldedRegisteredRecordsArePossible 
	|				THEN CASE 
	|						WHEN SettlementsAmounts.PrepaymentMan + SettlementsAmounts.ARAPMan < 0 
	|							THEN SettlementsAmounts.PrepaymentMan + SettlementsAmounts.ARAPMan
	|						ELSE 0
	|					END
	|			ELSE CASE
	|						WHEN SettlementsAmounts.PrepaymentMan < 0 
	|							THEN SettlementsAmounts.PrepaymentMan 
	|						ELSE 0 
	|					END 
	|				+ CASE 
	|						WHEN SettlementsAmounts.ARAPMan < 0
	|							THEN SettlementsAmounts.ARAPMan 
	|						ELSE 0 
	|					END
	|		END                                             AS AmountOfManReductionCalculations,
	|		CASE 
	|			WHEN NOT SettlementsAmounts.UnfoldedRegisteredRecordsArePossible
	|				THEN
	|					CASE
	|						WHEN ISNULL(DocumentAmounts_.AmountOfLocalIncrease,0) + ISNULL(DocumentAmounts_.AmountOfLocalReduction,0) > 0
	|							THEN ISNULL(DocumentAmounts_.AmountOfLocalIncrease,0) + ISNULL(DocumentAmounts_.AmountOfLocalReduction,0)
	|					ELSE 0
	|				END
	|			ELSE ISNULL(DocumentAmounts_.AmountOfLocalIncrease,0)
	|		END                                             AS AmountOfLocalIncrease,
	|		CASE 
	|			WHEN NOT SettlementsAmounts.UnfoldedRegisteredRecordsArePossible
	|				THEN
	|					CASE
	|						WHEN ISNULL(DocumentAmounts_.AmountOfManIncrease,0) + ISNULL(DocumentAmounts_.AmountOfManReduction,0) > 0
	|							THEN ISNULL(DocumentAmounts_.AmountOfManIncrease,0) + ISNULL(DocumentAmounts_.AmountOfManReduction,0)
	|					ELSE 0
	|				END
	|			ELSE ISNULL(DocumentAmounts_.AmountOfManIncrease,0)
	|		END                                             AS AmountOfManIncrease,
	|		CASE 
	|			WHEN NOT SettlementsAmounts.UnfoldedRegisteredRecordsArePossible
	|				THEN
	|					CASE
	|						WHEN ISNULL(DocumentAmounts_.AmountOfLocalIncrease,0) + ISNULL(DocumentAmounts_.AmountOfLocalReduction,0) < 0
	|							THEN ISNULL(DocumentAmounts_.AmountOfLocalIncrease,0) + ISNULL(DocumentAmounts_.AmountOfLocalReduction,0)
	|					ELSE 0
	|				END
	|			ELSE ISNULL(DocumentAmounts_.AmountOfLocalReduction,0)
	|		END                                             AS AmountOfLocalReduction,
	|		CASE 
	|			WHEN NOT SettlementsAmounts.UnfoldedRegisteredRecordsArePossible
	|				THEN
	|					CASE
	|						WHEN ISNULL(DocumentAmounts_.AmountOfManIncrease,0) + ISNULL(DocumentAmounts_.AmountOfManReduction,0) < 0
	|							THEN ISNULL(DocumentAmounts_.AmountOfManIncrease,0) + ISNULL(DocumentAmounts_.AmountOfManReduction,0)
	|					ELSE 0
	|				END
	|			ELSE ISNULL(DocumentAmounts_.AmountOfManReduction,0)
	|		END                                             AS AmountOfManReduction
	|	FROM
	|		TTSettlementAmounts AS SettlementsAmounts
	|			LEFT JOIN TTAmountOfDocuments AS DocumentAmounts_
	|				ON SettlementsAmounts.Recorder = DocumentAmounts_.Recorder
	|					AND SettlementsAmounts.PaymentType_ = DocumentAmounts_.PaymentType_
	|					AND SettlementsAmounts.ARAPObject = DocumentAmounts_.ARAPObject
	|	
	|	UNION ALL
	|	
	|	//Total amounts of adjustments
	|	SELECT
	|		SettlementAmounts.PaymentType_                                         AS PaymentType_,
	|		SettlementAmounts.Recorder                                         AS Recorder,
	|		SettlementAmounts.ARAPObject                                      AS ARAPObject,
	|		
	|		CAST(SettlementAmounts.AmountOfLocalSettlements / SettlementAmounts.AmountARAP AS NUMBER(30,10))
	|		 * SettlementAmounts.Total_Amount                                       AS SumIncreaseLocalCalculations,
	|		
	|		CAST((SettlementAmounts.AmountOfLocalSettlements / SettlementAmounts.AmountARAP) AS NUMBER(30,10))
	|			/ (CAST(SettlementAmounts.AmountOfLocalSettlements / SettlementAmounts.AmountOfManSettlements AS NUMBER(30,10)))
	|			* SettlementAmounts.Total_Amount                                    AS AmountOfManIncreaseCalculations,
	|		
	|		- CAST(SettlementAmounts.AmountOfLocalSettlements / SettlementAmounts.AmountARAP AS NUMBER(30,10))
	|			* SettlementAmounts.Total_Amount                                    AS SumReductionLocalCalculations,
	|	
	|		CAST(-(SettlementAmounts.AmountOfLocalSettlements / SettlementAmounts.AmountARAP) AS NUMBER(30,10))
	|			/ CAST((SettlementAmounts.AmountOfLocalSettlements / SettlementAmounts.AmountOfManSettlements) AS NUMBER(30,10))
	|			* SettlementAmounts.Total_Amount                                    AS AmountOfManReductionCalculations,
	|		
	|		0                                                                 AS AmountOfLocalIncrease,
	|		0                                                                 AS AmountOfManIncrease,
	|		0                                                                 AS AmountOfLocalReduction,
	|		0                                                                 AS AmountOfManReduction
	|	FROM
	|		TTAmountsOfSettlementsAdjustments AS SettlementAmounts
	|	WHERE
	|		SettlementAmounts.AmountARAP <> 0
	|		AND SettlementAmounts.AmountOfManSettlements <> 0) AS NestedQuery
	|WHERE
	|	NOT &ThisIsTest 
	|	OR CASE 
	|			WHEN NestedQuery.DocumentRecorder REFS Document.CustomerInvoice
	|				THEN CAST(NestedQuery.DocumentRecorder AS Document.CustomerInvoice).Status <> VALUE(Enum.StatusesOfCustomerInvoices.InTransit)
	|				WHEN NestedQuery.DocumentRecorder REFS Document.CustomerInvoiceServicesAndAssets
	|				THEN CAST(NestedQuery.DocumentRecorder AS Document.CustomerInvoiceServicesAndAssets).Status <> VALUE(Enum.StatusesOfCustomerInvoices.InTransit)
	|			ELSE TRUE
	|		END
	|
	|GROUP BY
	|	NestedQuery.PaymentType_,
	|	NestedQuery.ARAPObject,
	|	NestedQuery.DocumentRecorder
	|
	|HAVING
	|	(CAST(SUM(NestedQuery.SumIncreaseLocalCalculations) AS NUMBER(30,2)) <> SUM(NestedQuery.AmountOfLocalIncrease)
	|	OR CAST(SUM(NestedQuery.AmountOfManIncreaseCalculations) AS NUMBER(30,2)) <> SUM(NestedQuery.AmountOfManIncrease)
	|	OR CAST(SUM(NestedQuery.SumReductionLocalCalculations) AS NUMBER(30,2)) <> SUM(NestedQuery.AmountOfLocalReduction)
	|	OR CAST(SUM(NestedQuery.AmountOfManReductionCalculations) AS NUMBER(30,2)) <> SUM(NestedQuery.AmountOfManReduction))
	|";
		
	Return ComparisonText;
	
EndFunction

Procedure UpdateDocumentRegisteredRecords(Ref, UpdateComposition)
	Var Table;
	
	BeginTransaction();
	Try
		Tables = DocumentsPosting.DocumentDataForPosting(Ref, UpdateComposition);
		
		Date = Common.ObjectAttributeValue(Ref, "Date");
		Document = DocumentsPosting.DocumentEmulation(Ref, Date);
		TempTableManager = New TempTablesManager();
		
		For Each UpdateDetails1 In UpdateComposition Do
			If Tables.Property("Table" + UpdateDetails1.Key, Table) And ValueIsFilled(Table) Then
				
								
				Set = UpdateDetails1.Value; // AccumulationRegisterRecordSet - 
				Set.Filter.Recorder.Set(Ref);
				Set.Load(Table);
				DocumentsPosting.SetAdditionalRegisterProperties(Set, Document, TempTableManager);
				Set.AdditionalProperties.Insert("SkipPeriodClosingCheck");
				Set.Write(True);
			EndIf;
		EndDo;
		
		DocumentsPosting.CreateTasksForDeferredRegisteredRecords(Document, TempTableManager);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		MessageText = NStr("vi = 'Không thể ghi lại các chuyển động %RefreshEnabled% do %Cause%';
							|ru = 'Не удалось записать движения %RefreshEnabled% по причине %Cause%';
							|en = 'Cannot record register records %RefreshEnabled%. Reason: %Cause%'; fa = 'Cannot record register records %RefreshEnabled%. Reason: %Cause%';
							|it = 'Impossibile registrare i movimenti %RefreshEnabled% a causa %Cause%';
							|pl = 'Nie można zapisać ruchu %RefreshEnabled% z powodu %Cause%';
							|tr = '%Cause% nedeniyle %RefreshEnabled% hareketleri kaydedilemedi'", Common.DefaultLanguageCode());
		MessageText = StrReplace(MessageText, "%RefreshEnabled%", Ref);
		MessageText = StrReplace(MessageText, "%Cause%", ErrorDescription());
		WriteLogEvent(
			NStr("vi = 'Cập nhật một phần các bản ghi kết chuyển của chứng từ';
				|ru = 'Частичное обновление движений документа';
				|en = 'Partial update of document records'; fa = 'Partial update of document records';
				|it = 'Aggiornamento parziale dei movimenti del documento';
				|pl = 'Częściowa aktualizacja ruchów dokumentu';
				|tr = 'Belge kayıtlarının kısmi güncellenmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, 
			MessageText);
		Raise;
	EndTry
EndProcedure

Function RequestTextForSettlementAmounts(TTName = "")
	
	QueryText = "
	|SELECT
	|	DocumentAmountsInAccountingCurrency.PaymentType_               AS PaymentType_,
	|	DocumentAmountsInAccountingCurrency.ARAPObject            AS ARAPObject,
	|	DocumentAmountsInAccountingCurrency.Recorder               AS Recorder,
	|	MAX(BEGINOFPERIOD(DocumentAmountsInAccountingCurrency.Period, DAY)) AS Period,
	|	SUM(CASE WHEN (DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl + DocumentAmountsInAccountingCurrency.VATAmountCompl) >= 0 
	|			THEN DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl + DocumentAmountsInAccountingCurrency.VATAmountCompl
	|		ELSE 0 
	|	END)                                               AS AmountOfLocalIncrease,
	|	SUM(CASE WHEN (DocumentAmountsInAccountingCurrency.AmountExcludingVATMan  + DocumentAmountsInAccountingCurrency.VATAmountMan) >= 0 
	|			THEN DocumentAmountsInAccountingCurrency.AmountExcludingVATMan + DocumentAmountsInAccountingCurrency.VATAmountMan
	|		ELSE 0 
	|	END)                                               AS AmountOfManIncrease,
	|	SUM(CASE WHEN (DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl + DocumentAmountsInAccountingCurrency.VATAmountCompl) < 0 
	|			THEN DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl + DocumentAmountsInAccountingCurrency.VATAmountCompl
	|		ELSE 0 
	|	END)                                               AS AmountOfLocalReduction,
	|	SUM(CASE WHEN (DocumentAmountsInAccountingCurrency.AmountExcludingVATMan + DocumentAmountsInAccountingCurrency.VATAmountMan) < 0 
	|			THEN DocumentAmountsInAccountingCurrency.AmountExcludingVATMan + DocumentAmountsInAccountingCurrency.VATAmountMan
	|		ELSE 0 
	|	END)                                               AS AmountOfManReduction
	|INTO TTAmountOfDocuments
	|FROM
	|	InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
	|WHERE
	|	(DocumentAmountsInAccountingCurrency.Recorder IN (&DocumentsArray) OR &AccordingToAllDocuments)
	|	AND DocumentAmountsInAccountingCurrency.RecalculateBasedOnARAPData
	|	AND (DocumentAmountsInAccountingCurrency.Currency <> DocumentAmountsInAccountingCurrency.ARAPObject.Organization.LocalAccountingCurrency
	|		AND DocumentAmountsInAccountingCurrency.ARAPCurrency <> DocumentAmountsInAccountingCurrency.ARAPObject.Organization.LocalAccountingCurrency
	|		OR DocumentAmountsInAccountingCurrency.Currency <> &CurrencyOfManAccounting
	|			AND DocumentAmountsInAccountingCurrency.ARAPCurrency <> &CurrencyOfManAccounting)
	|
	|GROUP BY
	|	DocumentAmountsInAccountingCurrency.Recorder,
	|	DocumentAmountsInAccountingCurrency.ARAPObject,
	|	DocumentAmountsInAccountingCurrency.PaymentType_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// Increase - increase in shipment/delivery.
	|// In the document totals there are lines with a minus (decrease) and plus (increase).
	|// In the calculations, these amounts are reflected separately and can be offset.
	|// Therefore, for comparison, the total amount is calculated from the mutual settlements, which is both in the increase in debt and in the decrease.
	|// Example: The adjustment reduces the shipment by 100 and increases by 120, the total amount will be 100.
	|// In comparison with the data of the amounts of documents, the total amount is taken + the collapsed amount of mutual settlements from the sum of mutual settlements.
	|// Example: The sum of settlements (Decrease) = 100 + 0, the sum of settlements increase = 100 + 20.
	|//
	|SELECT DISTINCT
	|	CustomersARAPAccounting.DocumentRecorder                           AS Recorder,
	|	CustomersARAPAccounting.ARAPObject                                AS ARAPObject,
	|	CustomersARAPAccounting.Currency                                        AS Currency,
	|	CAST(CustomersARAPAccounting.DocumentRecorder AS Document.SaleAdjustment).DocumentBasis AS LinkedDocument,
	|	CASE WHEN CAST(CustomersARAPAccounting.DocumentRecorder AS Document.SaleAdjustment).DocumentBasis REFS Document.CustomerInvoice
	|		THEN CAST(CustomersARAPAccounting.DocumentRecorder AS Document.SaleAdjustment).DocumentBasis.DateOfTransferOfTitleToGoods
	|		ELSE CAST(CustomersARAPAccounting.DocumentRecorder AS Document.SaleAdjustment).DocumentBasis.Date
	|	END                                                           AS Date,
	|	CustomersARAPAccounting.ARAPObject.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	CustomersARAPAccounting.ARAPObject.ForeignCurrencyTransaction                  AS ForeignCurrencyTransaction,
	|	CustomersARAPAccounting.ARAPObject.VATTaxation             AS VATTaxation,
	|	VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
	|	SUM(CASE WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN CustomersARAPAccounting.Debt
	|		ELSE CustomersARAPAccounting.Prepayment
	|	END)                                                             AS AmountIncrease,
	|	SUM(CASE WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN -CustomersARAPAccounting.Debt
	|		ELSE -CustomersARAPAccounting.Prepayment
	|	END)                                                          AS AmountDecrease
	|INTO TTRelatedAdjustmentDocuments
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccounting
	|		INNER JOIN TTAmountOfDocuments AS DocumentAmounts_
	|			ON DocumentAmounts_.Recorder = CustomersARAPAccounting.DocumentRecorder
	|WHERE
	|	CustomersARAPAccounting.DocumentRecorder REFS Document.SaleAdjustment
	|	AND CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement)
	|	AND CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)
	|	AND CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices)
	|GROUP BY
	|	CustomersARAPAccounting.DocumentRecorder,
	|	CustomersARAPAccounting.ARAPObject,
	|	CustomersARAPAccounting.Currency,
	|	CAST(CustomersARAPAccounting.DocumentRecorder AS Document.SaleAdjustment).DocumentBasis,
	|	CASE WHEN CAST(CustomersARAPAccounting.DocumentRecorder AS Document.SaleAdjustment).DocumentBasis REFS Document.CustomerInvoice
	|		THEN CAST(CustomersARAPAccounting.DocumentRecorder AS Document.SaleAdjustment).DocumentBasis.DateOfTransferOfTitleToGoods
	|		ELSE CAST(CustomersARAPAccounting.DocumentRecorder AS Document.SaleAdjustment).DocumentBasis.Date
	|	END,
	|	CustomersARAPAccounting.ARAPObject.Organization.LocalAccountingCurrency,
	|	CustomersARAPAccounting.ARAPObject.ForeignCurrencyTransaction,
	|	CustomersARAPAccounting.ARAPObject.VATTaxation
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VendorsARAPAccounting.DocumentRecorder                           AS Recorder,
	|	VendorsARAPAccounting.ARAPObject                                AS ARAPObject,
	|	VendorsARAPAccounting.Currency                                        AS Currency,
	|	CAST(VendorsARAPAccounting.DocumentRecorder AS Document.PurchaseAdjustment).DocumentBasis AS LinkedDocument,
	|	CAST(VendorsARAPAccounting.DocumentRecorder AS Document.PurchaseAdjustment).Date AS Date,
	|	VendorsARAPAccounting.ARAPObject.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	VendorsARAPAccounting.ARAPObject.ForeignCurrencyTransaction                  AS ForeignCurrencyTransaction,
	|	VendorsARAPAccounting.ARAPObject.VATTaxation             AS VATTaxation,
	|	VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
	|	SUM(CASE WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN VendorsARAPAccounting.Debt
	|		ELSE VendorsARAPAccounting.Prepayment
	|	END)                                                             AS AmountIncrease,
	|	SUM(CASE WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN -VendorsARAPAccounting.Debt
	|		ELSE -VendorsARAPAccounting.Prepayment
	|	END)                                                             AS AmountDecrease
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccounting
	|		INNER JOIN TTAmountOfDocuments AS DocumentAmounts_
	|			ON DocumentAmounts_.Recorder = VendorsARAPAccounting.DocumentRecorder
	|WHERE
	|	VendorsARAPAccounting.DocumentRecorder REFS Document.PurchaseAdjustment
	|	AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement)
	|	AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)
	|	AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices)
	|GROUP BY
	|	VendorsARAPAccounting.DocumentRecorder,
	|	VendorsARAPAccounting.ARAPObject,
	|	VendorsARAPAccounting.Currency,
	|	CAST(VendorsARAPAccounting.DocumentRecorder AS Document.PurchaseAdjustment).DocumentBasis,
	|	CAST(VendorsARAPAccounting.DocumentRecorder AS Document.PurchaseAdjustment).Date,
	|	VendorsARAPAccounting.ARAPObject.Organization.LocalAccountingCurrency,
	|	VendorsARAPAccounting.ARAPObject.ForeignCurrencyTransaction,
	|	VendorsARAPAccounting.ARAPObject.VATTaxation
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CustomersARAPAccounting.Recorder                                   AS Recorder,
	|	CustomersARAPAccounting.SalesOrder                                  AS ARAPObject,
	|	CustomersARAPAccounting.Currency                                        AS Currency,
	|	CAST(CustomersARAPAccounting.Recorder AS Document.SaleAdjustment).DocumentBasis AS LinkedDocument,
	|	CASE WHEN CAST(CustomersARAPAccounting.Recorder AS Document.SaleAdjustment).DocumentBasis REFS Document.CustomerInvoice
	|		THEN CAST(CustomersARAPAccounting.Recorder AS Document.SaleAdjustment).DocumentBasis.DateOfTransferOfTitleToGoods
	|		ELSE CAST(CustomersARAPAccounting.Recorder AS Document.SaleAdjustment).DocumentBasis.Date
	|	END                                                           AS Date,
	|	CustomersARAPAccounting.SalesOrder.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	CustomersARAPAccounting.SalesOrder.ForeignCurrencyTransaction                  AS ForeignCurrencyTransaction,
	|	CustomersARAPAccounting.SalesOrder.VATTaxation             AS VATTaxation,
	|	VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
	|	SUM(CASE WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN CustomersARAPAccounting.Debt
	|		ELSE CustomersARAPAccounting.Prepayment
	|	END)                                                             AS AmountIncrease,
	|	SUM(CASE WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN -CustomersARAPAccounting.Debt
	|		ELSE -CustomersARAPAccounting.Prepayment
	|	END)                                                          AS AmountDecrease
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccounting
	|		INNER JOIN TTAmountOfDocuments AS DocumentAmounts_
	|			ON DocumentAmounts_.Recorder = CustomersARAPAccounting.Recorder
	|WHERE
	|	CustomersARAPAccounting.Recorder REFS Document.SaleAdjustment
	|	AND CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement)
	|	AND CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)
	|	AND CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices)
	|GROUP BY
	|	CustomersARAPAccounting.Recorder,
	|	CustomersARAPAccounting.SalesOrder,
	|	CustomersARAPAccounting.Currency,
	|	CAST(CustomersARAPAccounting.Recorder AS Document.SaleAdjustment).DocumentBasis,
	|	CASE WHEN CAST(CustomersARAPAccounting.Recorder AS Document.SaleAdjustment).DocumentBasis REFS Document.CustomerInvoice
	|		THEN CAST(CustomersARAPAccounting.Recorder AS Document.SaleAdjustment).DocumentBasis.DateOfTransferOfTitleToGoods
	|		ELSE CAST(CustomersARAPAccounting.Recorder AS Document.SaleAdjustment).DocumentBasis.Date
	|	END
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VendorsARAPAccounting.Recorder                                   AS Recorder,
	|	VendorsARAPAccounting.PurchaseOrder                               AS ARAPObject,
	|	VendorsARAPAccounting.Currency                                        AS Currency,
	|	CAST(VendorsARAPAccounting.Recorder AS Document.PurchaseAdjustment).DocumentBasis AS LinkedDocument,
	|	CAST(VendorsARAPAccounting.Recorder AS Document.PurchaseAdjustment).Date AS Date,
	|	VendorsARAPAccounting.PurchaseOrder.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	VendorsARAPAccounting.PurchaseOrder.ForeignCurrencyTransaction                  AS ForeignCurrencyTransaction,
	|	VendorsARAPAccounting.PurchaseOrder.VATTaxation             AS VATTaxation,
	|	VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
	|	SUM(CASE WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN VendorsARAPAccounting.Debt
	|		ELSE VendorsARAPAccounting.Prepayment
	|	END)                                                             AS AmountIncrease,
	|	SUM(CASE WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN -VendorsARAPAccounting.Debt
	|		ELSE -VendorsARAPAccounting.Prepayment
	|	END)                                                             AS AmountDecrease
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments AS VendorsARAPAccounting
	|		INNER JOIN TTAmountOfDocuments AS DocumentAmounts_
	|			ON DocumentAmounts_.Recorder = VendorsARAPAccounting.Recorder
	|WHERE
	|	VendorsARAPAccounting.Recorder REFS Document.PurchaseAdjustment
	|	AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement)
	|	AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)
	|	AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices)
	|GROUP BY
	|	VendorsARAPAccounting.Recorder,
	|	VendorsARAPAccounting.PurchaseOrder,
	|	VendorsARAPAccounting.Currency,
	|	CAST(VendorsARAPAccounting.Recorder AS Document.PurchaseAdjustment).DocumentBasis,
	|	CAST(VendorsARAPAccounting.Recorder AS Document.PurchaseAdjustment).Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabDocuments.LinkedDocument              AS LinkedDocument,
	|	TabDocuments.Currency                         AS Currency,
	|	TabDocuments.BaseCurrency                  AS BaseCurrency,
	|	MAX(TabDocuments.SettlementCurrencyPeriod) AS SettlementCurrencyPeriod,
	|	MAX(TabDocuments.ManCurrencyPeriod)      AS ManCurrencyPeriod
	|INTO TTCoursePeriodsOfRelatedDocuments
	|FROM (
	|	SELECT
	|		TabDocuments.LinkedDocument       AS LinkedDocument,
	|		TabDocuments.Currency                  AS Currency,
	|		SettlementCurrencyRates_.BaseCurrency    AS BaseCurrency,
	|		SettlementCurrencyRates_.Period           AS SettlementCurrencyPeriod,
	|		DATETIME(1,1,1)                     AS ManCurrencyPeriod
	|	FROM
	|		TTRelatedAdjustmentDocuments AS TabDocuments
	|			INNER JOIN InformationRegister.RelativeExchangeRates AS SettlementCurrencyRates_
	|				ON SettlementCurrencyRates_.Currency = TabDocuments.Currency
	|					AND TabDocuments.LocalAccountingCurrency = SettlementCurrencyRates_.BaseCurrency
	|					AND TabDocuments.Date >= SettlementCurrencyRates_.Period
	|	
	|	UNION
	|	
	|	SELECT
	|		TabDocuments.LinkedDocument       AS LinkedDocument,
	|		TabDocuments.Currency                  AS Currency,
	|		ManSExchangeRates.BaseCurrency         AS BaseCurrency,
	|		DATETIME(1,1,1)                     AS SettlementCurrencyPeriod,
	|		ManSExchangeRates.Period                AS ManCurrencyPeriod
	|	FROM
	|		TTRelatedAdjustmentDocuments AS TabDocuments
	|		INNER JOIN InformationRegister.RelativeExchangeRates AS ManSExchangeRates
	|			ON ManSExchangeRates.Currency = &CurrencyOfManAccounting
	|				AND TabDocuments.LocalAccountingCurrency = ManSExchangeRates.BaseCurrency
	|				AND TabDocuments.Date >= ManSExchangeRates.Period) AS TabDocuments
	|GROUP BY
	|		TabDocuments.LinkedDocument,
	|		TabDocuments.Currency,
	|		TabDocuments.BaseCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Calculations.Recorder                    AS Recorder,
	|	Calculations.ARAPObject                 AS ARAPObject,
	|	Calculations.ForeignCurrencyTransaction                  AS ForeignCurrencyTransaction,
	|	Calculations.VATTaxation             AS VATTaxation,
	|	Calculations.LinkedDocument              AS LinkedDocument,
	|	Calculations.PaymentType_                    AS PaymentType_,
	|	Calculations.AmountDecrease                AS AmountDecrease,
	|	Calculations.AmountIncrease                AS AmountIncrease,
	|	CASE WHEN Calculations.AmountIncrease > -Calculations.AmountDecrease
	|		THEN -Calculations.AmountDecrease
	|		ELSE Calculations.AmountIncrease
	|	END                                  AS Total_Amount,
	|	SUM(Calculations.AmountARAP)     AS AmountARAP,
	|	SUM(Calculations.AmountOfLocalSettlements) AS AmountOfLocalSettlements,
	|	SUM(Calculations.AmountOfManSettlements)  AS AmountOfManSettlements,
	|	SUM(Calculations.AmountOfLocalSettlements) AS NumeratorLocal,
	|	SUM(Calculations.AmountARAP)     AS LocalDenominator,
	|	SUM(Calculations.AmountOfManSettlements)  AS NumeratorMan,
	|	SUM(Calculations.AmountARAP)     AS DenominatorOfMan
	|INTO TTAmountsOfSettlementsAdjustments
	|FROM (
	|	SELECT
	|		RelatedDocuments.Recorder                 AS Recorder,
	|		RelatedDocuments.ARAPObject              AS ARAPObject,
	|		RelatedDocuments.ForeignCurrencyTransaction               AS ForeignCurrencyTransaction,
	|		RelatedDocuments.VATTaxation          AS VATTaxation,
	|		RelatedDocuments.LinkedDocument           AS LinkedDocument,
	|		RelatedDocuments.PaymentType_                 AS PaymentType_,
	|		RelatedDocuments.AmountDecrease             AS AmountDecrease,
	|		RelatedDocuments.AmountIncrease             AS AmountIncrease,
	|		ISNULL(CustomersARAPAccountingByDueDates.Debt,0)     AS AmountARAP,
	|		ISNULL(CustomersARAPAccountingByDueDates.DebtLocal,0) AS AmountOfLocalSettlements,
	|		ISNULL(CustomersARAPAccountingByDueDates.ARAPMan,0)  AS AmountOfManSettlements
	|	FROM
	|		TTRelatedAdjustmentDocuments AS RelatedDocuments
	|			LEFT JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS CustomersARAPAccountingByDueDates
	|				ON RelatedDocuments.LinkedDocument = CustomersARAPAccountingByDueDates.DocumentRecorder
	|					AND RelatedDocuments.ARAPObject = CustomersARAPAccountingByDueDates.ARAPObject
	|					AND CustomersARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					AND CustomersARAPAccountingByDueDates.Debt > 0 
	|	WHERE
	|		&NewOnlineARAPAccounting
	|		AND RelatedDocuments.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RelatedDocuments.Recorder                    AS Recorder,
	|		RelatedDocuments.ARAPObject                 AS ARAPObject,
	|		RelatedDocuments.ForeignCurrencyTransaction                  AS ForeignCurrencyTransaction,
	|		RelatedDocuments.VATTaxation             AS VATTaxation,
	|		RelatedDocuments.LinkedDocument              AS LinkedDocument,
	|		RelatedDocuments.PaymentType_                    AS PaymentType_,
	|		RelatedDocuments.AmountDecrease                AS AmountDecrease,
	|		RelatedDocuments.AmountIncrease                AS AmountIncrease,
	|		ISNULL(VendorsARAPAccountingByDueDates.Debt,0)     AS AmountARAP,
	|		ISNULL(VendorsARAPAccountingByDueDates.DebtLocal,0) AS AmountOfLocalSettlements,
	|		ISNULL(VendorsARAPAccountingByDueDates.ARAPMan,0)  AS AmountOfManSettlements
	|	FROM
	|		TTRelatedAdjustmentDocuments AS RelatedDocuments
	|		LEFT JOIN AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccountingByDueDates
	|			ON RelatedDocuments.LinkedDocument = VendorsARAPAccountingByDueDates.DocumentRecorder
	|				AND RelatedDocuments.ARAPObject = VendorsARAPAccountingByDueDates.ARAPObject
	|				AND VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND VendorsARAPAccountingByDueDates.Debt > 0
	|	WHERE
	|		&NewOnlineARAPAccounting
	|		AND RelatedDocuments.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RelatedDocuments.Recorder                                                   AS Recorder,
	|		RelatedDocuments.ARAPObject                                                AS ARAPObject,
	|		RelatedDocuments.ForeignCurrencyTransaction                                                 AS ForeignCurrencyTransaction,
	|		RelatedDocuments.VATTaxation                                            AS VATTaxation,
	|		RelatedDocuments.LinkedDocument                                             AS LinkedDocument,
	|		RelatedDocuments.PaymentType_                                                   AS PaymentType_,
	|		RelatedDocuments.AmountDecrease                                               AS AmountDecrease,
	|		RelatedDocuments.AmountIncrease                                               AS AmountIncrease,
	|		CASE WHEN ISNULL(CustomersARAPAccounting.RecordType,UNDEFINED) = VALUE(AccumulationRecordType.Receipt)
	|			THEN ISNULL(CustomersARAPAccounting.Debt,0) + ISNULL(CustomersARAPAccounting.Prepayment,0)
	|			ELSE -ISNULL(CustomersARAPAccounting.Debt,0) - ISNULL(CustomersARAPAccounting.Prepayment,0)
	|		END                                                                            AS AmountARAP,
	|		CASE WHEN ISNULL(CustomersARAPAccounting.RecordType,UNDEFINED) = VALUE(AccumulationRecordType.Receipt)
	|			THEN ISNULL(CustomersARAPAccounting.DebtLocal,0) + ISNULL(CustomersARAPAccounting.PrepaymentLocal,0)
	|			ELSE -ISNULL(CustomersARAPAccounting.DebtLocal,0) - ISNULL(CustomersARAPAccounting.PrepaymentLocal,0)
	|		END                                                                            AS AmountOfLocalSettlements,
	|		CASE WHEN ISNULL(CustomersARAPAccounting.RecordType,UNDEFINED) = VALUE(AccumulationRecordType.Receipt)
	|			THEN ISNULL(CustomersARAPAccounting.ARAPMan,0) + ISNULL(CustomersARAPAccounting.PrepaymentMan,0)
	|			ELSE -ISNULL(CustomersARAPAccounting.ARAPMan,0) - ISNULL(CustomersARAPAccounting.PrepaymentMan,0)
	|		END                                                                            AS AmountOfManSettlements
	|	FROM
	|		TTRelatedAdjustmentDocuments AS RelatedDocuments
	|			LEFT JOIN AccumulationRegister.CustomersARAPAccountingByDocuments AS CustomersARAPAccounting
	|				ON RelatedDocuments.LinkedDocument = CustomersARAPAccounting.Recorder
	|					AND RelatedDocuments.ARAPObject = CustomersARAPAccounting.SalesOrder
	|	WHERE
	|		NOT &NewOnlineARAPAccounting
	|		AND RelatedDocuments.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RelatedDocuments.Recorder                                                   AS Recorder,
	|		RelatedDocuments.ARAPObject                                                AS ARAPObject,
	|		RelatedDocuments.ForeignCurrencyTransaction                                                 AS ForeignCurrencyTransaction,
	|		RelatedDocuments.VATTaxation                                            AS VATTaxation,
	|		RelatedDocuments.LinkedDocument                                             AS LinkedDocument,
	|		RelatedDocuments.PaymentType_                                                   AS PaymentType_,
	|		RelatedDocuments.AmountDecrease                                               AS AmountDecrease,
	|		RelatedDocuments.AmountIncrease                                               AS AmountIncrease,
	|		CASE WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN VendorsARAPAccounting.Debt + VendorsARAPAccounting.Prepayment
	|			ELSE -VendorsARAPAccounting.Debt - VendorsARAPAccounting.Prepayment
	|		END                                                                            AS AmountARAP,
	|		CASE WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN VendorsARAPAccounting.DebtLocal + VendorsARAPAccounting.PrepaymentLocal
	|			ELSE -VendorsARAPAccounting.DebtLocal - VendorsARAPAccounting.PrepaymentLocal
	|		END                                                                            AS AmountOfLocalSettlements,
	|		CASE WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN VendorsARAPAccounting.ARAPMan + VendorsARAPAccounting.PrepaymentMan
	|			ELSE -VendorsARAPAccounting.ARAPMan - VendorsARAPAccounting.PrepaymentMan
	|		END                                                                            AS AmountOfManSettlements
	|	FROM
	|		TTRelatedAdjustmentDocuments AS RelatedDocuments
	|			LEFT JOIN AccumulationRegister.VendorsARAPAccountingByDocuments AS VendorsARAPAccounting
	|				ON RelatedDocuments.LinkedDocument = VendorsARAPAccounting.Recorder
	|					AND RelatedDocuments.ARAPObject = VendorsARAPAccounting.PurchaseOrder
	|	WHERE
	|		NOT &NewOnlineARAPAccounting
	|		AND RelatedDocuments.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RelatedDocuments.Recorder                                                   AS Recorder,
	|		RelatedDocuments.ARAPObject                                                AS ARAPObject,
	|		RelatedDocuments.ForeignCurrencyTransaction                                                 AS ForeignCurrencyTransaction,
	|		RelatedDocuments.VATTaxation                                            AS VATTaxation,
	|		RelatedDocuments.LinkedDocument                                             AS LinkedDocument,
	|		RelatedDocuments.PaymentType_                                                   AS PaymentType_,
	|		RelatedDocuments.AmountDecrease                                               AS AmountDecrease,
	|		RelatedDocuments.AmountIncrease                                               AS AmountIncrease,
	|		CAST(RelatedDocuments.LinkedDocument AS Document.SourceDocument).DocumentAmount AS AmountARAP,
	|		CAST(RelatedDocuments.LinkedDocument AS Document.SourceDocument).SumCompl      AS AmountOfLocalSettlements,
	|		CAST(RelatedDocuments.LinkedDocument AS Document.SourceDocument).SumMan       AS AmountOfManSettlements
	|	FROM
	|		TTRelatedAdjustmentDocuments AS RelatedDocuments
	|	WHERE
	|		RelatedDocuments.LinkedDocument REFS Document.SourceDocument
	|) AS Calculations
	|GROUP BY
	|	Calculations.PaymentType_,
	|	Calculations.Recorder,
	|	Calculations.ARAPObject,
	|	Calculations.ForeignCurrencyTransaction,
	|	Calculations.VATTaxation,
	|	Calculations.LinkedDocument,
	|	CASE WHEN Calculations.AmountIncrease > Calculations.AmountDecrease 
	|			THEN Calculations.AmountDecrease
	|		ELSE Calculations.AmountIncrease
	|	END,
	|	Calculations.AmountDecrease,
	|	Calculations.AmountIncrease
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterData.PaymentType_                  AS PaymentType_,
	|	RegisterData.Recorder                  AS Recorder,
	|	RegisterData.ARAPObject               AS ARAPObject,
	|	RegisterData.UnfoldedRegisteredRecordsArePossible  AS UnfoldedRegisteredRecordsArePossible,
	|	MAX(RegisterData.ForeignCurrencyTransaction)      AS ForeignCurrencyTransaction,
	|	MAX(RegisterData.VATTaxation) AS VATTaxation,
	|	SUM(RegisterData.PrepaymentAmount_)       AS Prepayment,
	|	SUM(RegisterData.DebtAmount_)             AS Debt,
	|	SUM(RegisterData.PrepaymentLocal)        AS PrepaymentLocal,
	|	SUM(RegisterData.PrepaymentMan)         AS PrepaymentMan,
	|	SUM(RegisterData.DebtLocal)              AS DebtLocal,
	|	SUM(RegisterData.ARAPMan)               AS ARAPMan,
	|	SUM(RegisterData.AmountIsPrepaidBeforeShipment) AS PrepaymentBeforeShipment,
	|	SUM(RegisterData.LocalPrepaymentBeforeShipment) AS LocalPrepaymentBeforeShipment,
	|	SUM(RegisterData.PrepaymentAmount_)
	|		+ SUM(RegisterData.DebtAmount_)       AS SettlementAmount_1,
	|	SUM(RegisterData.PrepaymentLocal)
	|		+ SUM(RegisterData.DebtLocal)        AS LocalSettlementAmount,
	|	SUM(RegisterData.PrepaymentMan)
	|		+ SUM(RegisterData.ARAPMan)         AS AmountOfManSCalculations
	|INTO TTCollapsedAmountsOfMutualSettlements
	|FROM
	|	(
	|	//Amounts of documents with clients
	|	SELECT
	|		VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
	|		RegisterData.Recorder                                      AS Recorder,
	|		RegisterData.SalesOrder                                     AS ARAPObject,
	|		RegisterData.SalesOrder.ForeignCurrencyTransaction                       AS ForeignCurrencyTransaction,
	|		RegisterData.SalesOrder.VATTaxation                  AS VATTaxation,
	|	
	|		CASE
	|				WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|					THEN -RegisterData.Prepayment
	|				ELSE RegisterData.Prepayment
	|		END                                                           AS PrepaymentAmount_,
	|		CASE
	|				WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|					THEN -RegisterData.Prepayment
	|				ELSE RegisterData.Prepayment
	|		END                                                           AS AmountIsPrepaidBeforeShipment,
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN RegisterData.Debt
	|			WHEN RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
	|				OR RegisterData.Recorder REFS Document.ARAPSettlement
	|				AND RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|					THEN -RegisterData.Debt
	|				ELSE 0
	|		END                                                           AS DebtAmount_,
	|		CASE
	|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -RegisterData.PrepaymentLocal
	|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN RegisterData.PrepaymentLocal
	|			ELSE 0
	|		END                                                           AS PrepaymentLocal,
	|		
	|		CASE
	|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -RegisterData.PrepaymentLocal
	|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN RegisterData.PrepaymentLocal
	|			ELSE 0
	|		END                                                           AS LocalPrepaymentBeforeShipment,
	|		
	|		CASE 
	|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -RegisterData.PrepaymentMan
	|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN RegisterData.PrepaymentMan
	|			ELSE 0
	|		END                                                           AS PrepaymentMan,
	|	
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN RegisterData.DebtLocal
	|			WHEN RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
	|				OR RegisterData.Recorder REFS Document.ARAPSettlement
	|				AND RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|					THEN -RegisterData.DebtLocal
	|			ELSE 0
	|		END                                                           AS DebtLocal,
	|	
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN RegisterData.ARAPMan
	|			WHEN RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
	|				OR RegisterData.Recorder REFS Document.ARAPSettlement
	|				AND RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|					THEN -RegisterData.ARAPMan
	|			ELSE 0
	|		END                                                           AS ARAPMan,
	|		RegisterData.Recorder REFS Document.SaleAdjustment AS UnfoldedRegisteredRecordsArePossible
	|	
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDocuments AS RegisterData
	|			INNER JOIN TTAmountOfDocuments AS DocumentAmounts_
	|				ON DocumentAmounts_.Recorder = RegisterData.Recorder
	|					AND DocumentAmounts_.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|					AND DocumentAmounts_.ARAPObject = RegisterData.SalesOrder
	|	WHERE
	|		NOT &NewOnlineARAPAccounting
	|		AND RegisterData.Recorder IN (&DocumentsArray)
	|		AND NOT RegisterData.BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment),
	|												VALUE(Enum.BusinessTransactions.RemunerationDeductionByConsignor),
	|												VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction))
	|		AND (RegisterData.BusinessOperation <> VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
	|				OR VALUETYPE(RegisterData.Recorder) = TYPE(Document.ARAPSettlement) AND (RegisterData.Debt < 0 OR RegisterData.Prepayment < 0))
	|		AND NOT (RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|				AND RegisterData.SalesOrder.Organization = VALUE(Catalog.Companies.ManagementCompany))
	|		AND (RegisterData.Currency <> RegisterData.SalesOrder.Organization.LocalAccountingCurrency
	|			OR RegisterData.Currency <> &CurrencyOfManAccounting)
	|	
	|	UNION ALL
	|	
	|	//Implementations in the ""On the way"" status
	|	SELECT
	|		VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
	|		RegisterData.Recorder                                      AS Recorder,
	|		RegisterData.SalesOrder                                     AS ARAPObject,
	|		RegisterData.Recorder.ForeignCurrencyTransaction                        AS ForeignCurrencyTransaction,
	|		RegisterData.Recorder.VATTaxation                   AS VATTaxation,
	|
	|		RegisterData.Prepayment                                       AS PrepaymentAmount_,
	|		RegisterData.Prepayment                                       AS AmountIsPrepaidBeforeShipment,
	|		0                                                               AS DebtAmount_,
	|		RegisterData.PrepaymentLocal                                   AS PrepaymentLocal,
	|		RegisterData.PrepaymentLocal                                   AS LocalPrepaymentBeforeShipment,
	|		RegisterData.PrepaymentMan                                    AS PrepaymentMan,
	|		0                                                               AS DebtLocal,
	|		0                                                               AS ARAPMan,
	|		RegisterData.Recorder REFS Document.SaleAdjustment AS UnfoldedRegisteredRecordsArePossible
	|	
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDocuments AS RegisterData
	|			INNER JOIN TTAmountOfDocuments AS DocumentAmounts_
	|				ON DocumentAmounts_.Recorder = RegisterData.Recorder
	|					AND DocumentAmounts_.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|					AND DocumentAmounts_.ARAPObject = RegisterData.SalesOrder
	|	WHERE
	|		NOT &NewOnlineARAPAccounting
	|		AND RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment)
	|		AND CASE 
	|			WHEN RegisterData.Recorder REFS Document.CustomerInvoice
	|				THEN CAST(RegisterData.Recorder AS Document.CustomerInvoice).Status = VALUE(Enum.StatusesOfCustomerInvoices.InTransit)
	|				WHEN RegisterData.Recorder REFS Document.CustomerInvoiceServicesAndAssets
	|				THEN CAST(RegisterData.Recorder AS Document.CustomerInvoiceServicesAndAssets).Status = VALUE(Enum.StatusesOfCustomerInvoices.InTransit)
	|			ELSE FALSE
	|		END
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
	|		RegisterData.DocumentRecorder                              AS Recorder,
	|		RegisterData.ARAPObject                                   AS ARAPObject,
	|		RegisterData.ARAPObject.ForeignCurrencyTransaction                     AS ForeignCurrencyTransaction,
	|		RegisterData.ARAPObject.VATTaxation                AS VATTaxation,
	|		CASE
	|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN RegisterData.Prepayment
	|			ELSE -RegisterData.Prepayment
	|		END                                                          AS PrepaymentAmount_,
	|		CASE
	|			WHEN RegisterData.OccurrenceDate > DocumentAmounts_.Period
	|				THEN 0
	|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN RegisterData.Prepayment
	|			ELSE -RegisterData.Prepayment
	|		END                                                          AS AmountIsPrepaidBeforeShipment,
	|		CASE 
	|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -RegisterData.Debt
	|			ELSE RegisterData.Debt
	|		END                                                           AS DebtAmount_,
	|		CASE
	|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN RegisterData.PrepaymentLocal
	|			ELSE -RegisterData.PrepaymentLocal
	|		END                                                           AS PrepaymentLocal,
	|		CASE
	|			WHEN RegisterData.OccurrenceDate > DocumentAmounts_.Period
	|				THEN 0
	|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN RegisterData.PrepaymentLocal
	|			ELSE -RegisterData.PrepaymentLocal 
	|		END                                                           AS LocalPrepaymentBeforeShipment,
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|					THEN RegisterData.PrepaymentMan
	|			ELSE -RegisterData.PrepaymentMan
	|		END                                                           AS PrepaymentMan,
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -RegisterData.DebtLocal
	|			ELSE RegisterData.DebtLocal
	|		END                                                           AS DebtLocal,
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -RegisterData.ARAPMan
	|			ELSE RegisterData.ARAPMan
	|		END                                                           AS ARAPMan,
	|		RegisterData.DocumentRecorder REFS Document.SaleAdjustment AS UnfoldedRegisteredRecordsArePossible
	|	
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS RegisterData
	|			INNER JOIN TTAmountOfDocuments AS DocumentAmounts_
	|				ON DocumentAmounts_.Recorder = RegisterData.DocumentRecorder
	|					AND DocumentAmounts_.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|					AND DocumentAmounts_.ARAPObject = RegisterData.ARAPObject
	|	WHERE
	|		&NewOnlineARAPAccounting
	|		AND VALUETYPE(RegisterData.DocumentRecorder) <> TYPE(Document.ARAPAdjustment)
	|		AND NOT RegisterData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment),
	|				VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction),
	|				VALUE(Enum.BusinessTransactions.RemunerationOffsetWithCommissionAgentSPayment))
	|		AND (RegisterData.BusinessOperation <> VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
	|				OR VALUETYPE(RegisterData.DocumentRecorder) = TYPE(Document.ARAPSettlement))
	|		AND NOT (RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|				AND RegisterData.ARAPObject.Organization = VALUE(Catalog.Companies.ManagementCompany))
	|		AND (RegisterData.Currency <> RegisterData.ARAPObject.Organization.LocalAccountingCurrency
	|			OR RegisterData.Currency <> &CurrencyOfManAccounting)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
	|		RegisterData.DocumentRecorder                              AS Recorder,
	|		RegisterData.ARAPObject                                   AS ARAPObject,
	|		RegisterData.ARAPObject.ForeignCurrencyTransaction                     AS ForeignCurrencyTransaction,
	|		RegisterData.ARAPObject.VATTaxation                AS VATTaxation,
	|		RegisterData.Prepayment                                       AS PrepaymentAmount_,
	|		CASE
	|			WHEN RegisterData.OccurrenceDate > DocumentAmounts_.Period
	|				THEN 0
	|			ELSE RegisterData.Prepayment
	|		END                                                           AS AmountIsPrepaidBeforeShipment,
	|		RegisterData.Debt                                             AS DebtAmount_,
	|		RegisterData.PrepaymentLocal                                   AS PrepaymentLocal,
	|		CASE
	|			WHEN RegisterData.OccurrenceDate > DocumentAmounts_.Period
	|				THEN 0
	|			ELSE RegisterData.PrepaymentLocal 
	|		END                                                           AS LocalPrepaymentBeforeShipment,
	|		RegisterData.PrepaymentMan                                    AS PrepaymentMan,
	|		RegisterData.DebtLocal                                         AS DebtLocal,
	|		RegisterData.ARAPMan                                          AS ARAPMan,
	|		FALSE                                                            AS UnfoldedRegisteredRecordsArePossible
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS RegisterData
	|			INNER JOIN TTAmountOfDocuments AS DocumentAmounts_
	|				ON DocumentAmounts_.Recorder = RegisterData.DocumentRecorder
	|					AND DocumentAmounts_.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|					AND DocumentAmounts_.ARAPObject = RegisterData.ARAPObject
	|	WHERE
	|		&NewOnlineARAPAccounting
	|		AND VALUETYPE(RegisterData.DocumentRecorder) = TYPE(Document.ARAPAdjustment)
	|		AND NOT RegisterData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.CustomerPrepaymentSettlement))
	|		AND (RegisterData.Currency <> RegisterData.ARAPObject.Organization.LocalAccountingCurrency
	|			OR RegisterData.Currency <> &CurrencyOfManAccounting)
	|	
	|	UNION ALL
	|
	|	//Implementations in the ""On the way"" status
	|	SELECT
	|		VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting) AS PaymentType_,
	|		RegisterData.DocumentRecorder                              AS Recorder,
	|		RegisterData.ARAPObject                                   AS ARAPObject,
	|		RegisterData.DocumentRecorder.ForeignCurrencyTransaction                AS ForeignCurrencyTransaction,
	|		RegisterData.DocumentRecorder.VATTaxation           AS VATTaxation,
	|		RegisterData.Prepayment                                       AS PrepaymentAmount_,
	|		CASE
	|			WHEN RegisterData.OccurrenceDate <= DocumentAmounts_.Period
	|				THEN RegisterData.Prepayment
	|			ELSE 0
	|		END                                                           AS AmountIsPrepaidBeforeShipment,
	|		0                                                               AS DebtAmount_,
	|		RegisterData.PrepaymentLocal                                   AS PrepaymentLocal,
	|		CASE
	|			WHEN RegisterData.OccurrenceDate <= DocumentAmounts_.Period
	|				THEN RegisterData.PrepaymentLocal
	|			ELSE 0
	|		END                                                           AS LocalPrepaymentBeforeShipment,
	|		RegisterData.PrepaymentMan                                    AS PrepaymentMan,
	|		0                                                               AS DebtLocal,
	|		0                                                               AS ARAPMan,
	|		RegisterData.DocumentRecorder REFS Document.SaleAdjustment AS UnfoldedRegisteredRecordsArePossible
	|	
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS RegisterData
	|			INNER JOIN TTAmountOfDocuments AS DocumentAmounts_
	|				ON DocumentAmounts_.Recorder = RegisterData.DocumentRecorder
	|					AND DocumentAmounts_.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|					AND DocumentAmounts_.ARAPObject = RegisterData.ARAPObject
	|	WHERE
	|		&NewOnlineARAPAccounting
	|		AND RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment)
	|		AND CASE 
	|			WHEN RegisterData.DocumentRecorder REFS Document.CustomerInvoice
	|				THEN CAST(RegisterData.DocumentRecorder AS Document.CustomerInvoice).Status = VALUE(Enum.StatusesOfCustomerInvoices.InTransit)
	|				WHEN RegisterData.DocumentRecorder REFS Document.CustomerInvoiceServicesAndAssets
	|				THEN CAST(RegisterData.DocumentRecorder AS Document.CustomerInvoiceServicesAndAssets).Status = VALUE(Enum.StatusesOfCustomerInvoices.InTransit)
	|			ELSE FALSE
	|		END
	|	
	|	UNION ALL
	|	
	|	//Amounts of documents with suppliers
	|	SELECT
	|		VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
	|		RegisterData.Recorder                                         AS Recorder,
	|		RegisterData.PurchaseOrder                                     AS AccountingDimensionByPartners,
	|		RegisterData.PurchaseOrder.ForeignCurrencyTransaction                       AS ForeignCurrencyTransaction,
	|		RegisterData.PurchaseOrder.VATTaxation                  AS VATTaxation,
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN RegisterData.Prepayment
	|			ELSE -RegisterData.Prepayment
	|		END                                                              AS PrepaymentAmount_,
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN RegisterData.Prepayment
	|			ELSE -RegisterData.Prepayment
	|		END                                                              AS AmountIsPrepaidBeforeShipment,
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN RegisterData.Debt
	|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
	|				OR RegisterData.Recorder REFS Document.ARAPSettlement
	|				THEN -RegisterData.Debt
	|			ELSE 0
	|		END                                                              AS DebtAmount_,
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN RegisterData.PrepaymentLocal
	|			ELSE -RegisterData.PrepaymentLocal
	|		END                                                              AS PrepaymentLocal,
	|		CASE
	|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN RegisterData.PrepaymentLocal
	|			ELSE -RegisterData.PrepaymentLocal 
	|		END                                                              AS LocalPrepaymentBeforeShipment,
	|		
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN RegisterData.PrepaymentMan
	|			ELSE -RegisterData.PrepaymentMan
	|		END                                                              AS PrepaymentMan,
	|		
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN RegisterData.DebtLocal
	|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt) 
	|				AND RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
	|				OR RegisterData.Recorder REFS Document.ARAPSettlement
	|				THEN -RegisterData.DebtLocal
	|			ELSE 0
	|		END                                                              AS DebtLocal,
	|		
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN RegisterData.ARAPMan
	|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ARAPAdjustment)
	|				OR RegisterData.Recorder REFS Document.ARAPSettlement
	|				THEN -RegisterData.ARAPMan
	|			ELSE 0
	|		END                                                              AS ARAPMan,
	|		RegisterData.Recorder REFS Document.PurchaseAdjustment AS UnfoldedRegisteredRecordsArePossible
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDocuments AS RegisterData
	|			INNER JOIN TTAmountOfDocuments AS DocumentAmounts_
	|				ON DocumentAmounts_.Recorder = RegisterData.Recorder
	|					AND DocumentAmounts_.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|					AND DocumentAmounts_.ARAPObject = RegisterData.PurchaseOrder
	|	WHERE
	|		NOT &NewOnlineARAPAccounting
	|		AND NOT RegisterData.BusinessOperation IN (VALUE(Enum.BusinessTransactions.RemunerationDeductionByConsignor),
	|													VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction))
	|		AND (RegisterData.BusinessOperation <> VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
	|				OR VALUETYPE(RegisterData.Recorder) = TYPE(Document.ARAPSettlement) AND (RegisterData.Debt < 0 OR RegisterData.Prepayment < 0))
	|		AND NOT (RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|				AND RegisterData.PurchaseOrder.Organization = VALUE(Catalog.Companies.ManagementCompany))
	|		AND (RegisterData.Currency <> RegisterData.PurchaseOrder.Organization.LocalAccountingCurrency
	|			OR RegisterData.Currency <> &CurrencyOfManAccounting)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
	|		RegisterData.DocumentRecorder                                 AS Recorder,
	|		RegisterData.ARAPObject                                      AS ARAPObject,
	|		RegisterData.ARAPObject.ForeignCurrencyTransaction                        AS ForeignCurrencyTransaction,
	|		RegisterData.ARAPObject.VATTaxation                   AS VATTaxation,
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -RegisterData.Prepayment
	|			ELSE RegisterData.Prepayment
	|		END                                                              AS PrepaymentAmount_,
	|		CASE 
	|			WHEN RegisterData.OccurrenceDate > DocumentAmounts_.Period
	|				THEN 0
	|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -RegisterData.Prepayment
	|			ELSE RegisterData.Prepayment
	|		END                                                              AS AmountIsPrepaidBeforeShipment,
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense) 
	|			THEN -RegisterData.Debt
	|			ELSE RegisterData.Debt
	|		END                                                              AS DebtAmount_,
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -RegisterData.PrepaymentLocal
	|			ELSE RegisterData.PrepaymentLocal
	|		END                                                              AS PrepaymentLocal,
	|		CASE
	|			WHEN RegisterData.OccurrenceDate > DocumentAmounts_.Period
	|				THEN 0
	|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -RegisterData.PrepaymentLocal
	|			ELSE RegisterData.PrepaymentLocal 
	|		END                                                              AS LocalPrepaymentBeforeShipment,
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt) 
	|			THEN -RegisterData.PrepaymentMan
	|			ELSE RegisterData.PrepaymentMan
	|		END                                                              AS PrepaymentMan,
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense) 
	|			THEN -RegisterData.DebtLocal
	|			ELSE RegisterData.DebtLocal
	|		END                                                              AS DebtLocal,
	|		CASE WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Expense) 
	|			THEN -RegisterData.ARAPMan
	|			ELSE RegisterData.ARAPMan
	|		END                                                              AS ARAPMan,
	|		RegisterData.DocumentRecorder REFS Document.PurchaseAdjustment AS UnfoldedRegisteredRecordsArePossible
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS RegisterData
	|			INNER JOIN TTAmountOfDocuments AS DocumentAmounts_
	|				ON DocumentAmounts_.Recorder = RegisterData.DocumentRecorder
	|					AND DocumentAmounts_.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|					AND DocumentAmounts_.ARAPObject = RegisterData.ARAPObject
	|	WHERE
	|		&NewOnlineARAPAccounting
	|		AND VALUETYPE(RegisterData.DocumentRecorder) <> TYPE(Document.ARAPAdjustment)
	|		AND NOT (RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|				AND RegisterData.ARAPObject.Organization = VALUE(Catalog.Companies.ManagementCompany))
	|		AND NOT RegisterData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.RemunerationOffsetWithPaymentToConsignor),
	|				VALUE(Enum.BusinessTransactions.RemunerationDeductionByConsignor),
	|				VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction))
	|		AND (RegisterData.BusinessOperation <> VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
	|				OR VALUETYPE(RegisterData.DocumentRecorder) = TYPE(Document.ARAPSettlement))
	|		AND (RegisterData.Currency <> RegisterData.ARAPObject.Organization.LocalAccountingCurrency
	|			OR RegisterData.Currency <> &CurrencyOfManAccounting)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting) AS PaymentType_,
	|		RegisterData.DocumentRecorder                                 AS Recorder,
	|		RegisterData.ARAPObject                                      AS ARAPObject,
	|		RegisterData.ARAPObject.ForeignCurrencyTransaction                        AS ForeignCurrencyTransaction,
	|		RegisterData.ARAPObject.VATTaxation                   AS VATTaxation,
	|		RegisterData.Prepayment                                          AS PrepaymentAmount_,
	|		CASE 
	|			WHEN RegisterData.OccurrenceDate > DocumentAmounts_.Period
	|				THEN 0
	|			ELSE RegisterData.Prepayment
	|		END                                                              AS AmountIsPrepaidBeforeShipment,
	|		RegisterData.Debt                                                AS DebtAmount_,
	|		RegisterData.PrepaymentLocal                                      AS PrepaymentLocal,
	|		CASE
	|			WHEN RegisterData.OccurrenceDate > DocumentAmounts_.Period
	|				THEN 0
	|			ELSE RegisterData.PrepaymentLocal 
	|		END                                                              AS LocalPrepaymentBeforeShipment,
	|		RegisterData.PrepaymentMan                                       AS PrepaymentMan,
	|		RegisterData.DebtLocal                                            AS DebtLocal,
	|		RegisterData.ARAPMan                                             AS ARAPMan,
	|		FALSE                                                               AS UnfoldedRegisteredRecordsArePossible
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates AS RegisterData
	|			INNER JOIN TTAmountOfDocuments AS DocumentAmounts_
	|				ON DocumentAmounts_.Recorder = RegisterData.DocumentRecorder
	|					AND DocumentAmounts_.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|					AND DocumentAmounts_.ARAPObject = RegisterData.ARAPObject
	|	WHERE
	|		&NewOnlineARAPAccounting
	|		AND VALUETYPE(RegisterData.DocumentRecorder) = TYPE(Document.ARAPAdjustment)
	|		AND NOT RegisterData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.VendorPrepaymentSettlement))
	|		AND (RegisterData.Currency <> RegisterData.ARAPObject.Organization.LocalAccountingCurrency
	|			OR RegisterData.Currency <> &CurrencyOfManAccounting)
	|) AS RegisterData
	|GROUP BY 
	|	RegisterData.PaymentType_,
	|	RegisterData.Recorder,
	|	RegisterData.ARAPObject,
	|	RegisterData.UnfoldedRegisteredRecordsArePossible
	|;
	|SELECT
	|	DataFromARAPRegisters.PaymentType_                  AS PaymentType_,
	|	DataFromARAPRegisters.Recorder                  AS Recorder,
	|	DataFromARAPRegisters.ARAPObject               AS ARAPObject,
	|	DataFromARAPRegisters.UnfoldedRegisteredRecordsArePossible  AS UnfoldedRegisteredRecordsArePossible,
	|	DataFromARAPRegisters.ForeignCurrencyTransaction                AS ForeignCurrencyTransaction,
	|	DataFromARAPRegisters.VATTaxation           AS VATTaxation,
	|	DataFromARAPRegisters.Prepayment                   AS Prepayment,
	|	DataFromARAPRegisters.PrepaymentBeforeShipment         AS PrepaymentBeforeShipment,
	|	DataFromARAPRegisters.Debt                         AS Debt,
	|	DataFromARAPRegisters.PrepaymentLocal               AS PrepaymentLocal,
	|	DataFromARAPRegisters.LocalPrepaymentBeforeShipment     AS LocalPrepaymentBeforeShipment,
	|	DataFromARAPRegisters.PrepaymentMan                AS PrepaymentMan,
	|	DataFromARAPRegisters.DebtLocal                     AS DebtLocal,
	|	DataFromARAPRegisters.ARAPMan                      AS ARAPMan,
	|	ISNULL(AmountsOfAdjustments.NumeratorLocal, DataFromARAPRegisters.LocalSettlementAmount) AS NumeratorLocal,
	|	ISNULL(AmountsOfAdjustments.LocalDenominator, DataFromARAPRegisters.SettlementAmount_1) AS LocalDenominator,
	|	ISNULL(AmountsOfAdjustments.NumeratorMan, DataFromARAPRegisters.AmountOfManSCalculations) AS NumeratorMan,
	|	ISNULL(AmountsOfAdjustments.DenominatorOfMan, DataFromARAPRegisters.SettlementAmount_1) AS DenominatorOfMan
	|INTO TTName
	|FROM
	|	TTCollapsedAmountsOfMutualSettlements AS DataFromARAPRegisters
	|		LEFT JOIN TTAmountsOfSettlementsAdjustments AS AmountsOfAdjustments
	|			ON DataFromARAPRegisters.Recorder = AmountsOfAdjustments.Recorder
	|";
	
	QueryText = StrReplace(QueryText,"TTName", TTName);
	QueryText = StrReplace(QueryText,"INTO" + " " + Chars.LF, "");
	
	Return QueryText;
	
EndFunction

// Returns for each Registrar the settlement amounts in the regulated and management accounting currencies for distribution.
// Parameters:
//		ArrayOfLoggers - Array - Array of documents that need to calculate the amount.
// Returns:
//	ValueTable - Table of sums and coefficients:
//	 *	PaymentType_ - EnumRef.PartnersARAPAccountingTypes - the type of the registrar's calculations.
//	 *	Recorder - DocumentRef - The document for which the calculation was made.
//	 *	AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Partner accounting analytics.
//	 *	ForeignCurrencyTransaction - Boolean - Indicates payment in a foreign currency.
//	 *	VATTaxation - EnumRef.VATTaxationTypes - VAT taxation of the document.
//	 *	AmountARAP - Number - The amount of mutual settlements of the document is always positive.
//	 *	PrepaymentLocal - Number - The amount of the credited/refunded prepayment in the currency of regulated accounting.
//	 *	PrepaymentMan - Number - The amount of the credited/refunded prepayment in the currency of management accounting.
//	 *	DebtLocal - Number - The amount of the repaid/incurred debt in the currency of regulated accounting.
//	 *	ARAPMan - Number - The amount of the repaid/incurred debt in the currency of management accounting.
//	 *	LocalCoefficient - Number - The coefficient of conversion of the settlement amount into the currency of the regulated accounting of the grounds for adjustments.
//	 *	ManSCoefficient - Number - The coefficient of conversion of the amount of calculations into the currency of management accounting of the grounds for adjustments.
//
Function DocumentSumsForLineDistribution(ArrayOfLoggers = Undefined) Export
	
	Query = New Query;
	Query.Text = RequestTextForSettlementAmounts();
	
	Query.SetParameter("DocumentsArray", ArrayOfLoggers);
	Query.SetParameter("AccordingToAllDocuments", Not ValueIsFilled(ArrayOfLoggers));
	Query.SetParameter("NewOnlineARAPAccounting", Constants.NewOnlineARAPAccounting.Get());
	Query.SetParameter("CurrencyOfManAccounting", Constants.ManagementAccountingCurrency.Get());
	Result = Query.Execute();
	
	Return Result.Unload();
	
EndFunction

Procedure ConvertTableToAccountingCurrencies(TempTablesManager)
	
	QueryText = "
	|SELECT
	|	ISNULL(ARAPObjects.VATTaxation,
	|	                                UNDEFINED) AS VATTaxation,
	|	ISNULL(ARAPObjects.ForeignCurrencyTransaction, FALSE) AS ForeignCurrencyTransaction,
	|	TableOfGoods.DataSource,
	|	TableOfGoods.DistributeTotalAmount AS DistributeTotalAmount,
	|	TableOfGoods.Recorder AS Recorder,
	|	TableOfGoods.Period AS Period,
	|	TableOfGoods.Organization AS Organization,
	|	TableOfGoods.Currency AS Currency,
	|	TableOfGoods.ARAPCurrency AS ARAPCurrency,
	|	TableOfGoods.VATBasePeriod AS VATBasePeriod,
	|	TableOfGoods.DateOfCourse AS DateOfCourse,
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.RowID AS RowID,
	|	TableOfGoods.AmountExcludingVAT AS AmountExcludingVAT,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.AmountARAP AS AmountARAP,
	|	TableOfGoods.AmountVATARAP AS AmountVATARAP,
	|	TableOfGoods.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	TableOfGoods.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	TableOfGoods.VATAmountCompl AS VATAmountCompl,
	|	TableOfGoods.VATAmountMan AS VATAmountMan,
	|	TableOfGoods.RecordedInARAPAccounting AS RecordedInARAPAccounting,
	|	TableOfGoods.ARAPObject AS ARAPObject,
	|	TableOfGoods.RecalculateBasedOnARAPData AS RecalculateBasedOnARAPData,
	|	TableOfGoods.DoNotRecalculateVATAmounts AS DoNotRecalculateVATAmounts,
	|	TableOfGoods.Contract AS Contract,
	|	TableOfGoods.ContractRateOption AS ContractRateOption,
	|	CASE
	|		WHEN (TableOfGoods.AmountExcludingVAT + TableOfGoods.VATAmount) < 0
	|			THEN -1
	|		ELSE 1
	|	END AS Character
	|FROM
	|	DocumentDataPreliminary AS TableOfGoods
	|	LEFT JOIN
	|		Catalog.ARAPObjects AS ARAPObjects
	|		ON TableOfGoods.ARAPObject = ARAPObjects.Ref
	|
	|ORDER BY
	|	TableOfGoods.LineNumber,
	|	TableOfGoods.AmountExcludingVAT
	|
	|TOTALS
	|	SUM(AmountExcludingVAT),
	|	SUM(VATAmount),
	|	SUM(AmountExcludingVATCompl),
	|	SUM(AmountExcludingVATMan),
	|	SUM(VATAmountCompl),
	|	SUM(VATAmountMan),
	|	MAX(VATBasePeriod),
	|	MAX(DoNotRecalculateVATAmounts)
	|BY
	|	Recorder,
	|	Currency,
	|	Organization,
	|	DateOfCourse,
	|	Contract,
	|	ContractRateOption,
	|	ARAPCurrency,
	|	DistributeTotalAmount,
	|	DataSource,
	|	Character
	|";
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	
	SetOfDocumentSumRecords = InformationRegisters.DocumentAmountsInAccountingCurrency.CreateRecordSet();
	DocumentAmountsInAccountingCurrency = SetOfDocumentSumRecords.Unload(); // ValueTable -
	For Each Column In QueryResult.Columns Do
		If DocumentAmountsInAccountingCurrency.Columns.Find(Column.Name) <> Undefined Then
			Continue;
		EndIf;
		If Column.ValueType <> New TypeDescription("Undefined") Then
			ColumnTypesDetails = Column.ValueType;
		Else
			ColumnTypesDetails = Common.AllRefsTypeDetails();
		EndIf;
		DocumentAmountsInAccountingCurrency.Columns.Add(Column.Name, ColumnTypesDetails);
	EndDo;
	DocumentAmountsInAccountingCurrency.Columns.Delete("Active");
	DocumentAmountsInAccountingCurrency.Columns.Delete("PointInTime");
	
	CurrencyExchangeRateCache = ProcessingOfExchangeRatesTM.InitializeCurrencyExchangeRateCache();
	ContractExchangeRateCache = ProcessingOfExchangeRatesTM.InitializeCacheOfContractExchangeRates();
	
	SelectionByDocument = QueryResult.Select(QueryResultIteration.ByGroups);
	While SelectionByDocument.Next() Do
		
		CurrencySelection_1 = SelectionByDocument.Select(QueryResultIteration.ByGroups);
		While CurrencySelection_1.Next() Do
			
			SelectionByOrganization = CurrencySelection_1.Select(QueryResultIteration.ByGroups);
			While SelectionByOrganization.Next() Do
				
				SelectionByDate_ = SelectionByOrganization.Select(QueryResultIteration.ByGroups);
				While SelectionByDate_.Next() Do
					
					SelectionByContract = SelectionByDate_.Select(QueryResultIteration.ByGroups);
					While SelectionByContract.Next() Do
						
						SelectionBasedOnContractCurrencyExchangeRate = SelectionByContract.Select(QueryResultIteration.ByGroups);
						While SelectionBasedOnContractCurrencyExchangeRate.Next() Do
							
							SampleBySettlementCurrency = SelectionBasedOnContractCurrencyExchangeRate.Select(QueryResultIteration.ByGroups);
							While SampleBySettlementCurrency.Next() Do
								
								SelectionByTypeOfRecalculation = SampleBySettlementCurrency.Select(QueryResultIteration.ByGroups);
								While SelectionByTypeOfRecalculation.Next() Do
									
									SamplingByDataSource = SelectionByTypeOfRecalculation.Select(QueryResultIteration.ByGroups);
									If SelectionByTypeOfRecalculation.DistributeTotalAmount Then
										#Region DistributeTotalAmount
										While SamplingByDataSource.Next() Do
											SampleSign = SamplingByDataSource.Select(QueryResultIteration.ByGroups);
											While SampleSign.Next() Do
												If SampleSign.AmountExcludingVAT + SampleSign.VATAmount <> 0 Then
													RecalculateTableToCurrenciesWithDistributionOfTotalAmount(SampleSign, DocumentAmountsInAccountingCurrency, CurrencyExchangeRateCache, ContractExchangeRateCache);
												Else
													RecalculateTableToAccountingCurrenciesLineByLine(SampleSign, DocumentAmountsInAccountingCurrency, CurrencyExchangeRateCache, ContractExchangeRateCache);
												EndIf
											EndDo;
										EndDo;
										#EndRegion
									Else
										#Region ConversionAtExchangeRate
										While SamplingByDataSource.Next() Do
											SampleSign = SamplingByDataSource.Select(QueryResultIteration.ByGroups);
											While SampleSign.Next() Do
												RecalculateTableToAccountingCurrenciesLineByLine(SampleSign, DocumentAmountsInAccountingCurrency, CurrencyExchangeRateCache, ContractExchangeRateCache);
											EndDo;
										EndDo;
										#EndRegion
									EndIf;
								EndDo;
							EndDo;
						EndDo;
					EndDo;
				EndDo;
			EndDo;
		EndDo;
	EndDo;
	
	// Let's put the result in a temporary table
	ArrayOfSelectionFields = New Array;
	For Each Column In DocumentAmountsInAccountingCurrency.Columns Do
		ArrayOfSelectionFields.Add(Column.Name);
	EndDo;
	TextOfSelectionFields = StrConcat(ArrayOfSelectionFields, ",");
	
	QueryText = "
	|DROP DocumentDataPreliminary
	|;
	|SELECT
	|	&SelectionFields1
	|INTO DocumentAmountsInAccountingCurrency
	|FROM 
	|	&Table AS Table
	|INDEX BY
	|		Recorder,
	|		RowID,
	|		Period";
	QueryText = StrReplace(QueryText, "&SelectionFields1", TextOfSelectionFields);
	
	Query.Text = QueryText;
	Query.SetParameter("Table", DocumentAmountsInAccountingCurrency);
	
	Query.Execute();
	
EndProcedure

Procedure RecalculateTableToAccountingCurrenciesLineByLine(SampleSign, DocumentAmountsInAccountingCurrency, CurrencyExchangeRateCache, ContractExchangeRateCache)
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(SampleSign.Organization);
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	
	Selection = SampleSign.Select();
	While Selection.Next() Do
		NewRecord = DocumentAmountsInAccountingCurrency.Add();
		FillPropertyValues(NewRecord, Selection);
		
		// The Contract exchange rate is not used for payments in foreign currency, in accordance with cash flows
		ContractCourseIsApplicable = Not ThisIsCashFlowRecorder(Selection.Recorder) Or Selection.Currency = LocalAccountingCurrency;
		
		If Selection.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract 
			And Selection.Currency = Selection.ARAPCurrency
			And ContractCourseIsApplicable Then
			DocumentExchangeRate = ProcessingOfExchangeRatesTM.GetContractCurrencyExchangeRateFromCache(Selection.Contract, Selection.DateOfCourse, ContractExchangeRateCache);
		Else
			DocumentExchangeRate = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(Selection.Currency, Selection.DateOfCourse, CurrencyExchangeRateCache, LocalAccountingCurrency);
		EndIf;
		
		ExchangeRateOfLocalAccounting = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(LocalAccountingCurrency, Selection.DateOfCourse, CurrencyExchangeRateCache, LocalAccountingCurrency);
		If ExchangeRateOfLocalAccounting = 0 Then
			ExchangeRateOfLocalAccounting = 1;
		EndIf;
		
		VATBasePeriod = ?(ValueIsFilled(SampleSign.VATBasePeriod), SampleSign.VATBasePeriod, SampleSign.DateOfCourse);
		DocumentCurrencyRateForVATBase = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(SampleSign.Currency, VATBasePeriod, CurrencyExchangeRateCache, LocalAccountingCurrency);
		If DocumentCurrencyRateForVATBase = 0 Then
			DocumentCurrencyRateForVATBase = 1;
		EndIf; 
		
		Sum = Selection.AmountExcludingVAT + Selection.VATAmount;
		
		CalculateLocalVATAmount = False;
		If LocalAccountingCurrency = Selection.Currency Then   
			AmountIncludingVATCompl = Sum;
			VATAmountCompl = Selection.VATAmount;
			VATBaseLocal = AmountIncludingVATCompl - VATAmountCompl;
		ElsIf ValueIsFilled(Selection.AmountExcludingVATCompl) Then
			VATBaseLocal = Selection.AmountExcludingVATCompl;
			VATAmountCompl = 0;
			AmountIncludingVATCompl = VATBaseLocal;
		ElsIf LocalAccountingCurrency = Selection.ARAPCurrency Then  
			AmountIncludingVATCompl = Selection.AmountARAP;
			If ValueIsFilled(Selection.AmountVATARAP) Then
				VATAmountCompl = Selection.AmountVATARAP;
				VATBaseLocal = AmountIncludingVATCompl - VATAmountCompl;
			Else
				CalculateLocalVATAmount = True;
			EndIf;	
		Else
			AmountIncludingVATCompl = Round(Sum * DocumentExchangeRate / ExchangeRateOfLocalAccounting, 2);
			CalculateLocalVATAmount = True;
		EndIf;
		
		If Selection.DoNotRecalculateVATAmounts Then
			
			CalculateLocalVATAmount = False;
			VATAmountCompl =  Selection.VATAmountCompl;
			
		EndIf;
		
		If CalculateLocalVATAmount Then
			
			If Selection.VATTaxation = Enums.VATTaxationTypes.DigitalServices Then
				VATBaseLocal = Sum * DocumentExchangeRate;
				VATAmountCompl = PriceManagementSystemClientServer.CalculateVATAmount(AmountIncludingVATCompl, Selection.VATRate, False);
			ElsIf Selection.ForeignCurrencyTransaction  Then
				VATBaseLocal = Selection.AmountExcludingVAT * DocumentCurrencyRateForVATBase;
				If Selection.VATAmount = 0 Then 
					VATAmountCompl = 0;
				Else
					VATAmountCompl = PriceManagementSystemClientServer.CalculateVATAmount(VATBaseLocal, Selection.VATRate, False);
				EndIf;
			Else
				If Selection.VATAmount = 0 Then 
					VATAmountCompl = 0;
				Else
					VATAmountCompl = PriceManagementSystemClientServer.CalculateVATAmount(AmountIncludingVATCompl, Selection.VATRate);
				EndIf;
				VATBaseLocal = AmountIncludingVATCompl - VATAmountCompl;
			EndIf;
			
		ElsIf Selection.DoNotRecalculateVATAmounts Then
			
			If Selection.VATTaxation = Enums.VATTaxationTypes.DigitalServices Then
				VATBaseLocal = Sum * DocumentExchangeRate;
			ElsIf Selection.ForeignCurrencyTransaction Then
				VATBaseLocal = Selection.AmountExcludingVAT * DocumentCurrencyRateForVATBase;
			Else
				VATBaseLocal = AmountIncludingVATCompl - VATAmountCompl;
			EndIf;
			
		EndIf;
		
		NewRecord.VATAmountCompl =  VATAmountCompl;
		NewRecord.AmountExcludingVATCompl = AmountIncludingVATCompl - VATAmountCompl;
		NewRecord.VATBaseLocal = VATBaseLocal;
		
		If Selection.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract 
			And ManagementAccountingCurrency = Selection.ARAPCurrency
			And ContractCourseIsApplicable Then
			CurrencyExchangeRateManAccounting = ProcessingOfExchangeRatesTM.GetContractCurrencyExchangeRateFromCache(Selection.Contract, Selection.DateOfCourse, ContractExchangeRateCache);
		Else
			CurrencyExchangeRateManAccounting = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(ManagementAccountingCurrency, Selection.DateOfCourse, CurrencyExchangeRateCache, LocalAccountingCurrency);
		EndIf;
		If CurrencyExchangeRateManAccounting = 0 Then
			CurrencyExchangeRateManAccounting = 1;
		EndIf;
		
		If ManagementAccountingCurrency = Selection.Currency Then
			AmountIncludingVATMan = Sum;
		ElsIf ValueIsFilled(Selection.AmountExcludingVATMan) Then
			AmountIncludingVATMan = Selection.AmountExcludingVATMan;
		ElsIf ManagementAccountingCurrency = Selection.ARAPCurrency
			And Selection.AmountARAP <> 0 Then
			AmountIncludingVATMan = Selection.AmountARAP;
		Else
			AmountIncludingVATMan = Round(Sum * DocumentExchangeRate / CurrencyExchangeRateManAccounting, 2);
		EndIf;
		
		If Selection.DoNotRecalculateVATAmounts Then
			
			NewRecord.VATAmountMan = Selection.VATAmountMan;
			NewRecord.AmountExcludingVATMan = AmountIncludingVATMan - NewRecord.VATAmountMan;
			
		ElsIf Selection.AmountExcludingVAT = 0 Then
			NewRecord.VATAmountMan = AmountIncludingVATMan;
			NewRecord.AmountExcludingVATMan = 0;
		Else
			NewRecord.VATAmountMan = VATAmountCompl / CurrencyExchangeRateManAccounting;
			NewRecord.AmountExcludingVATMan = AmountIncludingVATMan - NewRecord.VATAmountMan;
		EndIf;
		
	EndDo

EndProcedure

Procedure RecalculateTableToCurrenciesWithDistributionOfTotalAmount(SampleSign, DocumentAmountsInAccountingCurrency, CurrencyExchangeRateCache, ContractExchangeRateCache)
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(SampleSign.Organization);
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	
	// The Contract exchange rate is not used for payments in foreign currency, in accordance with cash flows
	ContractCourseIsApplicable = Not ThisIsCashFlowRecorder(SampleSign.Recorder) Or SampleSign.Currency = LocalAccountingCurrency;
	
	ExchangeRateOfLocalAccounting = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(LocalAccountingCurrency, SampleSign.DateOfCourse, CurrencyExchangeRateCache, LocalAccountingCurrency);
	If ExchangeRateOfLocalAccounting = 0 Then
		ExchangeRateOfLocalAccounting = 1;
	EndIf;
	If SampleSign.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract 
		And SampleSign.Currency = SampleSign.ARAPCurrency
		And ContractCourseIsApplicable Then
		DocumentExchangeRate = ProcessingOfExchangeRatesTM.GetContractCurrencyExchangeRateFromCache(SampleSign.Contract, SampleSign.DateOfCourse, ContractExchangeRateCache);
	Else
		DocumentExchangeRate = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(SampleSign.Currency, SampleSign.DateOfCourse, CurrencyExchangeRateCache, LocalAccountingCurrency);
	EndIf;
	
	If SampleSign.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract 
		And ManagementAccountingCurrency = SampleSign.ARAPCurrency
		And ContractCourseIsApplicable Then
		CurrencyExchangeRateManAccounting = ProcessingOfExchangeRatesTM.GetContractCurrencyExchangeRateFromCache(SampleSign.Contract, SampleSign.DateOfCourse, ContractExchangeRateCache);
	Else
		CurrencyExchangeRateManAccounting = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(ManagementAccountingCurrency, SampleSign.DateOfCourse, CurrencyExchangeRateCache, LocalAccountingCurrency);
	EndIf;
	If CurrencyExchangeRateManAccounting = 0 Then
		CurrencyExchangeRateManAccounting = 1;
	EndIf;
	
	VATBasePeriod = ?(ValueIsFilled(SampleSign.VATBasePeriod), SampleSign.VATBasePeriod, SampleSign.DateOfCourse);
	DocumentCurrencyRateForVATBase = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(SampleSign.Currency, VATBasePeriod, CurrencyExchangeRateCache, LocalAccountingCurrency);
	If DocumentCurrencyRateForVATBase = 0 Then
		DocumentCurrencyRateForVATBase = 1;
	EndIf;
	
	TotalAmount_1 = SampleSign.AmountExcludingVAT + SampleSign.VATAmount;
	If ValueIsFilled(SampleSign.AmountExcludingVATCompl) Then
		TotalLocalAmount = SampleSign.AmountExcludingVATCompl;
	Else
		TotalLocalAmount = Round(TotalAmount_1 * DocumentExchangeRate / ExchangeRateOfLocalAccounting, 2);
	EndIf;
	If ValueIsFilled(SampleSign.AmountExcludingVATMan) Then
		TotalAmountOfMan = SampleSign.AmountExcludingVATMan;
	Else
		TotalAmountOfMan = Round(TotalAmount_1 * DocumentExchangeRate / CurrencyExchangeRateManAccounting, 2);
	EndIf;
	Allocated = 0;
	DistributedByLocal = 0;
	DistributedByMan = 0;
	
	Selection = SampleSign.Select();
	While Selection.Next() Do
		
		Sum = Selection.AmountExcludingVAT + Selection.VATAmount;
		
		NewRecord = DocumentAmountsInAccountingCurrency.Add();
		FillPropertyValues(NewRecord, Selection);
		
		CalculateLocalVATAmount = False;
		
		If LocalAccountingCurrency = Selection.Currency Then
			AmountIncludingVATCompl = Sum;
			VATAmountCompl = Selection.VATAmount;
			VATBaseLocal = AmountIncludingVATCompl - VATAmountCompl;
		ElsIf ValueIsFilled(Selection.AmountExcludingVATCompl) Then
			AmountIncludingVATCompl = Selection.AmountExcludingVATCompl;
			VATAmountCompl = 0;
			VATBaseLocal = AmountIncludingVATCompl;
		ElsIf LocalAccountingCurrency = Selection.ARAPCurrency
			And Selection.AmountARAP <> 0 Then
			AmountIncludingVATCompl = Selection.AmountARAP;
			If ValueIsFilled(Selection.AmountVATARAP) Then
				VATAmountCompl = Selection.AmountVATARAP;
				VATBaseLocal = AmountIncludingVATCompl - VATAmountCompl;
			Else
				CalculateLocalVATAmount = True;
			EndIf;
		Else
			AmountIncludingVATCompl = Round(TotalLocalAmount * (Allocated + Sum) / TotalAmount_1, 2) - DistributedByLocal;
			CalculateLocalVATAmount = True;
		EndIf;
		
		If Selection.DoNotRecalculateVATAmounts Then
			
			CalculateLocalVATAmount = False;
			VATAmountCompl =  Selection.VATAmountCompl;
			
		EndIf;
		
		If CalculateLocalVATAmount Then
			
			If Selection.VATTaxation = Enums.VATTaxationTypes.DigitalServices Then
				VATBaseLocal = (Selection.AmountExcludingVAT + Selection.VATAmount) * DocumentExchangeRate;
				VATAmountCompl = PriceManagementSystemClientServer.CalculateVATAmount(AmountIncludingVATCompl, Selection.VATRate, False);
			ElsIf Selection.ForeignCurrencyTransaction  Then
				VATBaseLocal = Selection.AmountExcludingVAT * DocumentCurrencyRateForVATBase;
				If Selection.VATAmount = 0 Then 
					VATAmountCompl = 0;
				Else
					VATAmountCompl = PriceManagementSystemClientServer.CalculateVATAmount(VATBaseLocal, Selection.VATRate, False);
				EndIf;
			Else
				If Selection.VATAmount = 0 Then 
					VATAmountCompl = 0;
				Else
					VATAmountCompl = PriceManagementSystemClientServer.CalculateVATAmount(AmountIncludingVATCompl, Selection.VATRate);
				EndIf;
				VATBaseLocal = AmountIncludingVATCompl - VATAmountCompl;
			EndIf;
			
		ElsIf Selection.DoNotRecalculateVATAmounts Then
			
			If Selection.VATTaxation = Enums.VATTaxationTypes.DigitalServices Then
				VATBaseLocal = (Selection.AmountExcludingVAT + Selection.VATAmount) * DocumentExchangeRate;
			ElsIf Selection.ForeignCurrencyTransaction Then
				VATBaseLocal = Selection.AmountExcludingVAT * DocumentCurrencyRateForVATBase;
			Else
				VATBaseLocal = AmountIncludingVATCompl - VATAmountCompl;
			EndIf;
			
		EndIf;
		
		DistributedByLocal = DistributedByLocal + AmountIncludingVATCompl;
		NewRecord.VATAmountCompl = VATAmountCompl;
		NewRecord.AmountExcludingVATCompl = AmountIncludingVATCompl - VATAmountCompl;
		NewRecord.VATBaseLocal = VATBaseLocal;
		
		If ManagementAccountingCurrency = Selection.Currency Then
			AmountIncludingVATMan = Sum;
		ElsIf ValueIsFilled(Selection.AmountExcludingVATMan) Then
			AmountIncludingVATMan = Selection.AmountExcludingVATMan;
		ElsIf ManagementAccountingCurrency = Selection.ARAPCurrency
			And Selection.AmountARAP <> 0 Then
			AmountIncludingVATMan = Selection.AmountARAP;
		Else
			AmountIncludingVATMan = Round(TotalAmountOfMan * (Allocated + Sum) / TotalAmount_1, 2) - DistributedByMan;
		EndIf;
		DistributedByMan = DistributedByMan + AmountIncludingVATMan;
		
		If Selection.DoNotRecalculateVATAmounts Then
			
			NewRecord.VATAmountMan = Selection.VATAmountMan;
			NewRecord.AmountExcludingVATMan = AmountIncludingVATMan - NewRecord.VATAmountMan;
			
		ElsIf Selection.AmountExcludingVAT = 0 Then
			NewRecord.VATAmountMan = AmountIncludingVATMan;
			NewRecord.AmountExcludingVATMan = 0;
		Else
			NewRecord.VATAmountMan = VATAmountCompl / CurrencyExchangeRateManAccounting;
			NewRecord.AmountExcludingVATMan = AmountIncludingVATMan - NewRecord.VATAmountMan;
		EndIf;
		
		Allocated = Allocated + Sum;
		
	EndDo;

EndProcedure

Function ThisIsCashFlowRecorder(DocumentRef)
	
	Return
		Metadata.AccumulationRegisters.BankAccountCash.StandardAttributes.Recorder.Type.ContainsType(TypeOf(DocumentRef))
		Or Metadata.AccumulationRegisters.CashAccountBalance.StandardAttributes.Recorder.Type.ContainsType(TypeOf(DocumentRef));

EndFunction

#Region Discounting 

// Calculate discounting.
// 
// Parameters:
//  DocumentsArray - Array of DocumentRef - List of documents to be calculated
// 
// Returns:
//  Array of DocumentRef - Documents To Be Recalculated
//
Function CalculateDiscounting(DocumentsArray) Export
	
	ParametersForCalculatingDiscounting = ParametersForCalculatingDocumentDiscounting(DocumentsArray);
	SelectionByDocuments = ParametersForCalculatingDiscounting.SelectionByDocuments;
	// Redefine the array for documents whose discounting has actually changed
	DocumentsToBeRecalculated = New Array;
	DocumentAmountTable = CreateRecordSet().UnloadColumns();
	While SelectionByDocuments.Next() Do
		
		CalculateDiscountingByDocument(SelectionByDocuments, ParametersForCalculatingDiscounting, DocumentAmountTable, DocumentsToBeRecalculated);
		
	EndDo;
	
	If DocumentsToBeRecalculated.Count() > 0 Then
		UpdateDocumentRegisteredRecords_(DocumentsToBeRecalculated);
	EndIf;
	
	Return DocumentsToBeRecalculated;
	
EndFunction

Function TextOfDiscountDataRequest()

	QueryText = 
	"SELECT
	|	VendorsARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccountingByDueDates.Currency AS Currency,
	|	VendorsARAPAccountingByDueDates.ARAPObject AS ARAPObject,
	|	VendorsARAPAccountingByDueDates.ARAPDocument AS ARAPDocument,
	|	VendorsARAPAccountingByDueDates.PlannedRepaymentDate AS PlannedRepaymentDate,
	|	VendorsARAPAccountingByDueDates.OccurrenceDate AS OccurrenceDate,
	|	CASE WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN VendorsARAPAccountingByDueDates.Debt
	|		ELSE 0 
	|	END AS Debt,
	|	CASE WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN VendorsARAPAccountingByDueDates.ARAPMan
	|		ELSE 0 
	|	END AS ARAPMan,
	|	CASE WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN VendorsARAPAccountingByDueDates.DebtLocal
	|		ELSE 0 
	|	END AS DebtLocal,
	|	CASE WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|	            AND VendorsARAPAccountingByDueDates.DocumentRecorder = VendorsARAPAccountingByDueDates.ARAPDocument
	|		THEN VendorsARAPAccountingByDueDates.Debt
	|		ELSE 0 
	|	END AS AdvanceAmount,
	|	CASE WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|	            AND VendorsARAPAccountingByDueDates.DocumentRecorder = VendorsARAPAccountingByDueDates.ARAPDocument
	|		THEN VendorsARAPAccountingByDueDates.ARAPMan
	|		ELSE 0 
	|	END AS AdvanceAmountOfMan,
	|	CASE WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|	            AND VendorsARAPAccountingByDueDates.DocumentRecorder = VendorsARAPAccountingByDueDates.ARAPDocument
	|		THEN VendorsARAPAccountingByDueDates.DebtLocal
	|		ELSE 0 
	|	END AS AmountOfSchedAdvance,
	|	CASE
	|		WHEN VendorsARAPAccountingByDueDates.OccurrenceDate > VendorsARAPAccountingByDueDates.PlannedRepaymentDate
	|			THEN 0
	|		ELSE DATEDIFF(VendorsARAPAccountingByDueDates.OccurrenceDate, VendorsARAPAccountingByDueDates.PlannedRepaymentDate, DAY)
	|	END AS DeferredPayment,
	|	DimensionKeysOfAccountingByPartners.Contract AS Contract,
	|	CounterpartyContracts.DiscountRate AS DiscountRate,
	|	CounterpartyContracts.ApplicationDiscountingPeriod AS ApplicationDiscountingPeriod,
	|	CounterpartyContracts.ContractRateOption AS ContractRateOption,
	|	DimensionKeysOfAccountingByPartners.Organization AS Organization,
	|	CASE WHEN VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN VendorsARAPAccountingByDueDates.Period
	|		ELSE DATETIME(1, 1, 1)
	|	END  AS Period,
	|	Companies.ParentCompany AS ParentCompany
	|INTO TTPaymentSchedule
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccountingByDueDates
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			INNER JOIN Catalog.Companies AS Companies
	|			ON DimensionKeysOfAccountingByPartners.Organization = Companies.Ref
	|			INNER JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|			ON DimensionKeysOfAccountingByPartners.Contract = CounterpartyContracts.Ref
	|		ON VendorsARAPAccountingByDueDates.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|		LEFT JOIN Document.PurchaseAdjustment AS PurchaseAdjustment
	|		ON VendorsARAPAccountingByDueDates.ARAPDocument = PurchaseAdjustment.Ref
	|WHERE
	|	VendorsARAPAccountingByDueDates.Active
	|	AND CounterpartyContracts.DiscountRate > 0
	|	AND VendorsARAPAccountingByDueDates.ARAPDocument IN(&DocumentsArray)
	|	AND VALUETYPE(VendorsARAPAccountingByDueDates.ARAPDocument) IN (&TypesOfDocumentsInvolvedInDiscounting)
	|	AND NOT VALUETYPE(VendorsARAPAccountingByDueDates.DocumentRecorder) IN (TYPE(Document.ExchangeDifferenceCalculation), TYPE(Document.OBEntryARAP))
	|	AND (PurchaseAdjustment.DocumentBasis IS NULL
	|			OR (VALUETYPE(PurchaseAdjustment.DocumentBasis) IN (&TypesOfDocumentsInvolvedInDiscounting)))
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	Currency,
	|	ARAPObject,
	|	ARAPDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPaymentSchedule.OccurrenceDate AS OccurrenceDate,
	|	MAX(FinancialAccountingPolicy.Period) AS Period,
	|	FinancialAccountingPolicy.Organization AS Organization
	|INTO TTAccountingPolicyPeriods
	|FROM
	|	TTPaymentSchedule AS TTPaymentSchedule
	|		INNER JOIN InformationRegister.FinancialAccountingPolicy AS FinancialAccountingPolicy
	|		ON TTPaymentSchedule.ParentCompany = FinancialAccountingPolicy.Organization
	|			AND TTPaymentSchedule.OccurrenceDate >= FinancialAccountingPolicy.Period
	|
	|GROUP BY
	|	TTPaymentSchedule.OccurrenceDate,
	|	FinancialAccountingPolicy.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAccountingPolicyPeriods.OccurrenceDate AS OccurrenceDate,
	|	TTAccountingPolicyPeriods.Period AS Period,
	|	TTAccountingPolicyPeriods.Organization AS Organization
	|INTO TTAccountingPolicy
	|FROM
	|	TTAccountingPolicyPeriods AS TTAccountingPolicyPeriods
	|		INNER JOIN InformationRegister.FinancialAccountingPolicy AS FinancialAccountingPolicy
	|		ON TTAccountingPolicyPeriods.Period = FinancialAccountingPolicy.Period
	|			AND TTAccountingPolicyPeriods.Organization = FinancialAccountingPolicy.Organization
	|WHERE
	|	FinancialAccountingPolicy.AccountingForDiscountedAccountsPayableToVendors
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDeferral.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TTDeferral.Currency AS Currency,
	|	TTDeferral.ARAPObject AS ARAPObject,
	|	TTDeferral.ARAPDocument AS ARAPDocument,
	|	TTDeferral.DiscountRate AS DiscountRate,
	|	TTDeferral.ApplicationDiscountingPeriod AS ApplicationDiscountingPeriod,
	|	TTDeferral.ContractRateOption AS ContractRateOption
	|INTO TTDeferral
	|FROM
	|	TTPaymentSchedule AS TTDeferral
	|		INNER JOIN TTAccountingPolicy AS TTAccountingPolicy
	|		ON TTDeferral.ParentCompany = TTAccountingPolicy.Organization
	|			AND TTDeferral.OccurrenceDate = TTAccountingPolicy.OccurrenceDate
	|WHERE
	|	TTDeferral.ApplicationDiscountingPeriod < TTDeferral.DeferredPayment
	|
	|GROUP BY
	|	TTDeferral.AccountingDimensionByPartners,
	|	TTDeferral.ARAPObject,
	|	TTDeferral.Currency,
	|	TTDeferral.ARAPDocument,
	|	TTDeferral.ApplicationDiscountingPeriod,
	|	TTDeferral.DiscountRate,
	|	TTDeferral.ContractRateOption
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	Currency,
	|	ARAPObject,
	|	ARAPDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPaymentSchedule.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	TTPaymentSchedule.Currency AS Currency,
	|	TTPaymentSchedule.ARAPObject AS ARAPObject,
	|	TTPaymentSchedule.ARAPDocument AS ARAPDocument,
	|	CASE
	|		WHEN TTPaymentSchedule.OccurrenceDate > TTPaymentSchedule.PlannedRepaymentDate
	|			THEN TTPaymentSchedule.OccurrenceDate
	|		ELSE TTPaymentSchedule.PlannedRepaymentDate
	|	END AS PlannedRepaymentDate,
	|	TTPaymentSchedule.OccurrenceDate AS OccurrenceDate,
	|	TTPaymentSchedule.Debt AS Debt,
	|	TTPaymentSchedule.ARAPMan AS ARAPMan,
	|	TTPaymentSchedule.DebtLocal AS DebtLocal,
	|	TTPaymentSchedule.AdvanceAmount AS AdvanceAmount,
	|	TTPaymentSchedule.AdvanceAmountOfMan AS AdvanceAmountOfMan,
	|	TTPaymentSchedule.AmountOfSchedAdvance AS AmountOfSchedAdvance,
	|	TTPaymentSchedule.DeferredPayment AS DeferredPayment,
	|	TTDeferral.DiscountRate AS DiscountRate,
	|	TTDeferral.ContractRateOption AS ContractRateOption,
	|	TTPaymentSchedule.Contract AS Contract,
	|	TTPaymentSchedule.Organization AS Organization,
	|	TTPaymentSchedule.Period AS Period,
	|	TTPaymentSchedule.ARAPObject.UUID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AccrualOfInterestOnDiscounting) AS BusinessTransactionSetting
	|FROM
	|	TTPaymentSchedule AS TTPaymentSchedule
	|		INNER JOIN TTDeferral AS TTDeferral
	|		ON TTPaymentSchedule.AccountingDimensionByPartners = TTDeferral.AccountingDimensionByPartners
	|			AND TTPaymentSchedule.Currency = TTDeferral.Currency
	|			AND TTPaymentSchedule.ARAPObject = TTDeferral.ARAPObject
	|			AND TTPaymentSchedule.ARAPDocument = TTDeferral.ARAPDocument
	|
	|ORDER BY
	|	PlannedRepaymentDate
	|TOTALS
	|	MAX(AccountingDimensionByPartners),
	|	MAX(Currency),
	|	MAX(OccurrenceDate),
	|	MAX(DiscountRate),
	|	MAX(Organization),
	|	MAX(Period),
	|	MAX(Contract),
	|	MAX(ContractRateOption),
	|	MAX(BusinessTransactionSetting)
	|BY
	|	ARAPDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DiscountInterestExpense.ARAPDocument AS ARAPDocument
	|FROM
	|	AccumulationRegister.DiscountInterestExpense AS DiscountInterestExpense
	|WHERE
	|	DiscountInterestExpense.Active
	|	AND DiscountInterestExpense.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND VALUETYPE(DiscountInterestExpense.Recorder) IN (&TypesOfDocumentsInvolvedInDiscounting)
	|	AND VALUETYPE(DiscountInterestExpense.Recorder) <> TYPE(Document.OBEntryARAP)
	|	AND DiscountInterestExpense.ARAPDocument IN(&DocumentsArray)
	|	AND NOT DiscountInterestExpense.ReversingEntry
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VendorsARAPAccountingByDueDates.Period AS Period,
	|	VendorsARAPAccountingByDueDates.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccountingByDueDates.ARAPObject AS ARAPObject,
	|	VendorsARAPAccountingByDueDates.Currency AS Currency,
	|	VendorsARAPAccountingByDueDates.ARAPDocument AS ARAPDocument,
	|	VendorsARAPAccountingByDueDates.Debt AS Debt,
	|	VendorsARAPAccountingByDueDates.DebtLocal AS DebtLocal,
	|	VendorsARAPAccountingByDueDates.ARAPMan AS ARAPMan,
	|	CounterpartyContracts.DiscountRate AS DiscountRate,
	|	VendorsARAPAccountingByDueDates.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.DiscountingInterestWriteOff) AS BusinessTransactionSetting,
	|	VendorsARAPAccountingByDueDates.DocumentRecorder AS DocumentRecorder,
	|	TRUE IN
	|		(SELECT TOP 1 TRUE
	|			FROM AccumulationRegister.DiscountInterestExpense AS T
	|			WHERE T.Recorder = VendorsARAPAccountingByDueDates.DocumentRecorder) AS ThereAreRegisterRecordsOfDiscounting
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS VendorsARAPAccountingByDueDates
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			INNER JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|			ON DimensionKeysOfAccountingByPartners.Contract = CounterpartyContracts.Ref
	|		ON VendorsARAPAccountingByDueDates.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|WHERE
	|	VendorsARAPAccountingByDueDates.Active
	|	AND VendorsARAPAccountingByDueDates.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND VendorsARAPAccountingByDueDates.DocumentRecorder IN(&DocumentsArray)
	|	AND VALUETYPE(VendorsARAPAccountingByDueDates.DocumentRecorder) = TYPE(Document.PurchaseAdjustment)
	|TOTALS
	|	MAX(Period),
	|	MAX(AccountingDimensionByPartners),
	|	MAX(Currency),
	|	MAX(ARAPDocument),
	|	MAX(DiscountRate),
	|	MAX(BusinessTransactionSetting),
	|	MAX(ThereAreRegisterRecordsOfDiscounting)
	|BY
	|	DocumentRecorder";
	
	Return QueryText;
	
EndFunction

// Returns compliance with payment schedules and data of settlement documents that need to be discounted.
//
// Parameters:
//  DocumentsArray - Array - An array of documents for which you need to check the need for discounting and get a payment schedule.
//  PaymentType_ - String - The type of calculations for which discounting will be performed 
//	                       It can take the values "Calculation by clients" or "Calculation by suppliers". 
//	                       So far, discounting is supported only for "settlements by suppliers".
//  ArrayToBeCalculated - Array - Optional, the transmitted array will contain the documents that need to be discounted 
// 
// Returns:
//	- Undefined - For the calculation type "Calculation by clients" (not supported yet).
//	- Map of See DocumentDataStructureForDiscounting. 
//	- Map of Structure: 
//	 	* Clear_InterestAccrual - Boolean - A flag for clearing document movements by the percentages of discounting register if discounting is stopped.
//	 	* ThisIsNegativeAdjustment - Boolean - a sign that a negative acquisition adjustment is being discounted.
//
Function PaymentSchedulesForDiscounting(DocumentsArray, PaymentType_, ArrayToBeCalculated = Undefined)
	
	If PaymentType_ <> "VendorsARAPAccounting" Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("DocumentsArray", DocumentsArray);
	Query.SetParameter("TypesOfDocumentsInvolvedInDiscounting",
		AccumulationRegisters.DiscountInterestExpense.GetTypesOfDocumentsInvolvedInDiscounting());
	Query.Text = TextOfDiscountDataRequest();
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	SelectionByDocuments = Result[4].Select(QueryResultIteration.ByGroups);
	SamplingAccruedInterest = Result[5].Select();
	SamplingNegativeAdjustments = Result[6].Select(QueryResultIteration.ByGroups);
	
	DataForDiscounting = New Map;
	While SelectionByDocuments.Next() Do
		DocumentStructure = DocumentDataStructureForDiscounting();
		FillPropertyValues(DocumentStructure, SelectionByDocuments);
		DocumentStructure.ThisIsNegativeAdjustment = False;
		
		SampleGraph = SelectionByDocuments.Select();
		
		While SampleGraph.Next() Do
			NewRow = DocumentStructure.PaymentSchedule.Add();
			NewRow.PayDate = SampleGraph.PlannedRepaymentDate;
			NewRow.PayAmount = SampleGraph.Debt;
			NewRow.ManPaymentAmount = SampleGraph.ARAPMan;
			NewRow.PaymentAmountLocal = SampleGraph.DebtLocal;
			NewRow.AdvanceAmount = SampleGraph.AdvanceAmount;
			NewRow.AdvanceAmountOfMan = SampleGraph.AdvanceAmountOfMan;
			NewRow.AmountOfSchedAdvance = SampleGraph.AmountOfSchedAdvance;
			NewRow.ARAPObject = SampleGraph.ARAPObject;
			NewRow.FinRecordID = SampleGraph.FinRecordID;
			NewRow.ThisIsAdvance = SampleGraph.Debt = 0;
		EndDo;
		
		DataForDiscounting[SelectionByDocuments.ARAPDocument] = DocumentStructure;
		If ArrayToBeCalculated <> Undefined Then
			ArrayToBeCalculated.Add(SelectionByDocuments.ARAPDocument);
		EndIf;
		
	EndDo;
	
	While SamplingAccruedInterest.Next() Do
		If DataForDiscounting[SamplingAccruedInterest.ARAPDocument] = Undefined Then
			// Discounting has been stopped for the document, the present value is recalculated again and interest accrual movements are cleared
			DataForDiscounting[SamplingAccruedInterest.ARAPDocument] = New Structure("Clear_InterestAccrual, ThisIsNegativeAdjustment", True, False);
			If ArrayToBeCalculated <> Undefined Then
				ArrayToBeCalculated.Add(SamplingAccruedInterest.ARAPDocument);
			EndIf;
		EndIf;
	EndDo;
	
	While SamplingNegativeAdjustments.Next() Do
		
		DocumentStructure = DocumentDataStructureForDiscounting();
		FillPropertyValues(DocumentStructure, SamplingNegativeAdjustments);
		DocumentStructure.ThisIsNegativeAdjustment = True;
		SelectionOfCalculationObjects = SamplingNegativeAdjustments.Select();
		While SelectionOfCalculationObjects.Next() Do
			NewRow = DocumentStructure.PaymentSchedule.Add();
			NewRow.PayAmount = SelectionOfCalculationObjects.Debt;
			NewRow.ManPaymentAmount = SelectionOfCalculationObjects.ARAPMan;
			NewRow.PaymentAmountLocal = SelectionOfCalculationObjects.DebtLocal;
			NewRow.ARAPObject = SelectionOfCalculationObjects.ARAPObject;
			NewRow.FinRecordID = SelectionOfCalculationObjects.FinRecordID;
		EndDo;
		
		DataForDiscounting[SamplingNegativeAdjustments.DocumentRecorder] = DocumentStructure;
		If ArrayToBeCalculated <> Undefined Then
			ArrayToBeCalculated.Add(SamplingNegativeAdjustments.DocumentRecorder);
		EndIf;
		
	EndDo;
	
	Return DataForDiscounting;
	
EndFunction

// Returns an empty structure for storing document data required for discounting
// 
// Returns:
//  Structure:
//	 *	AccountingDimensionByPartners - CatalogRef - Analysis of the settlement document
//	 *	Currency - CatalogRef.Currencies - The currency of mutual settlements
//	 *	ARAPDocument - DocumentRef.VendorInvoice,
//	 	                    Document link.Purchasingservicesother assets,
//	 	                    Document link.Acquisition adjustment
//	 *	OccurrenceDate - Date - Date of purchase
//	 *	DiscountRate - Number - The percentage by which the discounting is performed
//	 *	Contract - CatalogRef.CounterpartyContracts - to obtain exchange rates under the Contract
//	 *	ContractRateOption - EnumRef.ContractRateOptions - to determine the need to obtain exchange rates under the Contract
//	 *	Organization - CatalogRef.Companies - Organization of the settlement document
//	 *	Period - Date - Time of purchase
//	 *	BusinessTransactionSetting - CatalogRef.BusinessTransactionsSettings - Setting up a business discounting operation
//	 *	DiscountRate_ - Number - The ratio of the discounted (present) value to the actual debt at the time of acquisition
//	 *	ThisIsNegativeAdjustment - Boolean - an indication that a negative acquisition adjustment is discounted
//	 *	ThereAreRegisterRecordsOfDiscounting - Boolean - A flag indicating the presence of discount movements in a negative correction
//	 *	PaymentSchedule - ValueTable - Table with payment schedule data:
//	 	**	ARAPObject - CatalogRef.ARAPObjects - The object of calculations of the settlement document 
//	 	**	PayDate - Date - Payment schedule dates
//	 	**	PayAmount - Number - Payment schedule amounts, including VAT
//	 	**	ManPaymentAmount - Number - payment schedule amounts in Man's accounting currency, including vat
//	 	**	PaymentAmountLocal - Number - payment schedule amounts in Local accounting currency, including vat
//	 	**	AdvanceAmount - Number - The amount of the advance payment on the receipt document
//	 	**	AdvanceAmountOfMan - Number - the amount of the advance payment for the receipt document in the currency of the Man account
//	 	**	AmountOfSchedAdvance - Number - the amount of the advance payment for the receipt document in the currency of Local accounting
//	 	**	DiscountingAmount - Number - the calculated amount of interest in the currency of mutual settlements
//	 	**	DiscountingAmountMan - Number - the calculated amount of interest in the currency of Management accounting
//	 	**	DiscountingAmountCompl - Number - the calculated amount of interest in the currency of the Regulated accounting of the organization
//	 	**	FinRecordID - String - ID to display an entry in financial accounting
//	 	**	ActualDebtWithoutVAT - Number - Actual debt expected at the end of the month of acquisition
//	 	**	DiscountedDebtWithoutVAT - Number - Discounted debt expected at the end of the month of acquisition
//	 	**	CalculatedInterestBalance - Number - calculated interest Balance after interest expense discount is written off at the end of the month of purchase
//	 	**	ThisIsAdvance - Boolean - A sign indicating the amount of the advance
Function DocumentDataStructureForDiscounting()
	
	Result = New Structure;
	Result.Insert("AccountingDimensionByPartners");
	Result.Insert("Currency");
	Result.Insert("ARAPDocument");
	Result.Insert("OccurrenceDate");
	Result.Insert("DiscountRate");
	Result.Insert("Organization");
	Result.Insert("Period");
	Result.Insert("BusinessTransactionSetting");
	Result.Insert("DiscountRate_");
	Result.Insert("ThisIsNegativeAdjustment");
	Result.Insert("Contract");
	Result.Insert("ContractRateOption");
	Result.Insert("ThereAreRegisterRecordsOfDiscounting", False);
	
	PaymentSchedule = New ValueTable;
	
	PaymentSchedule.Columns.Add("ARAPObject", TMCommonUse.DescriptionOfTypesByType(Type("CatalogRef.ARAPObjects")));
	PaymentSchedule.Columns.Add("PayDate", TMCommonUse.DescriptionOfTypesByType(Type("Date")));
	PaymentSchedule.Columns.Add("PayAmount", TMCommonUse.MoneyFieldTypeDescription());
	PaymentSchedule.Columns.Add("ManPaymentAmount", TMCommonUse.MoneyFieldTypeDescription());
	PaymentSchedule.Columns.Add("PaymentAmountLocal", TMCommonUse.MoneyFieldTypeDescription());
	PaymentSchedule.Columns.Add("AdvanceAmount", TMCommonUse.MoneyFieldTypeDescription());
	PaymentSchedule.Columns.Add("AdvanceAmountOfMan", TMCommonUse.MoneyFieldTypeDescription());
	PaymentSchedule.Columns.Add("AmountOfSchedAdvance", TMCommonUse.MoneyFieldTypeDescription());
	PaymentSchedule.Columns.Add("DiscountingAmount", TMCommonUse.MoneyFieldTypeDescription());
	PaymentSchedule.Columns.Add("DiscountingAmountMan", TMCommonUse.MoneyFieldTypeDescription());
	PaymentSchedule.Columns.Add("DiscountingAmountCompl", TMCommonUse.MoneyFieldTypeDescription());
	PaymentSchedule.Columns.Add("FinRecordID", TMCommonUse.DescriptionOfTypesByType(Type("String")));
	PaymentSchedule.Columns.Add("ActualDebtWithoutVAT", TMCommonUse.MoneyFieldTypeDescription());
	PaymentSchedule.Columns.Add("DiscountedDebtWithoutVAT", TMCommonUse.MoneyFieldTypeDescription());
	PaymentSchedule.Columns.Add("CalculatedInterestBalance", TMCommonUse.MoneyFieldTypeDescription());
	PaymentSchedule.Columns.Add("ActualDebtWithoutVATCompl", TMCommonUse.MoneyFieldTypeDescription());
	PaymentSchedule.Columns.Add("DiscountedDebtWithoutVATCompl", TMCommonUse.MoneyFieldTypeDescription());
	PaymentSchedule.Columns.Add("CalculatedInterestBalanceCompl", TMCommonUse.MoneyFieldTypeDescription());
	PaymentSchedule.Columns.Add("ActualDebtWithoutVATMan", TMCommonUse.MoneyFieldTypeDescription());
	PaymentSchedule.Columns.Add("DiscountedDebtWithoutVATMan", TMCommonUse.MoneyFieldTypeDescription());
	PaymentSchedule.Columns.Add("CalculatedInterestBalanceMan", TMCommonUse.MoneyFieldTypeDescription());
	PaymentSchedule.Columns.Add("ThisIsAdvance", TMCommonUse.DescriptionOfTypesByType(Type("Boolean")));
	
	PaymentSchedule.Indexes.Add("ThisIsAdvance");
	
	Result.Insert("PaymentSchedule", PaymentSchedule);
	
	Return Result;
	
EndFunction

Function PresentValueOfPayments(DiscountRate, PaymentDates, PaymentAmounts, DateOfCasting)
	
	// For CHISTNZ, it is mandatory to add the first line of the schedule line on the date of bringing,
	// in case there is no payment on that day
	PaymentDates.Insert(0, DateOfCasting);
	PaymentAmounts.Insert(0, 0);
	
	PresentValue = FinancialInstruments.Thorns(DiscountRate, PaymentAmounts, PaymentDates);
	
	// Let's return the arrays to their original form
	PaymentDates.Delete(0);
	PaymentAmounts.Delete(0);
	
	Return Round(PresentValue, 2);
	
EndFunction

Function ListDocumentAmounts(DataOfPaymentSchedule, DocumentAmountTable, CurrencyExchangeRateCache, ContractExchangeRateCache, Document)

	DiscountingApplied = False;
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	HasChanges = False;
	
	If DataOfPaymentSchedule <> Undefined 
		And DataOfPaymentSchedule[Document] <> Undefined 
		And NewOnlineARAPAccounting Then
		
		DocumentDataStructure = DataOfPaymentSchedule[Document];
		
		If DocumentDataStructure.Property("Clear_InterestAccrual")
			And DocumentDataStructure.Clear_InterestAccrual Then
			// It is necessary to record the set if the discounting has already been recorded, but no longer applies 
			HasChanges = True;
		ElsIf Not DocumentDataStructure.ThisIsNegativeAdjustment Then
			
			// It is necessary to calculate the amounts given for each Settlement Object separately
			ResultTable1 = DocumentDataStructure.PaymentSchedule.CopyColumns(); // ValueTable
			
			TableGrouping = DocumentDataStructure.PaymentSchedule.Copy(
				New Structure("ThisIsAdvance", False),
				"ARAPObject, 
				|FinRecordID, 
				|PayAmount, 
				|PaymentAmountLocal, 
				|ManPaymentAmount"); // ValueTable
			TableGrouping.Indexes.Add("ARAPObject, FinRecordID");
			TableGrouping.GroupBy("ARAPObject, FinRecordID", "PayAmount, PaymentAmountLocal, ManPaymentAmount");
			TableOfAdvances = DocumentDataStructure.PaymentSchedule.Copy(
				New Structure("ThisIsAdvance", True),
				"ARAPObject, 
				|PayDate, 
				|AdvanceAmount, 
				|AmountOfSchedAdvance, 
				|AdvanceAmountOfMan"); // ValueTable
			TableOfAdvances.Indexes.Add("ARAPObject, PayDate");
			TableOfAdvances.GroupBy("ARAPObject, PayDate", "AdvanceAmount, AmountOfSchedAdvance, AdvanceAmountOfMan");
			
			// Therefore, we will divide the amounts of the document between the objects of calculations
			TableGrouping.Columns.Add("AmountARAP", TMCommonUse.MoneyFieldTypeDescription());
			
			CoefficientOfAmountWithoutVAT = ?(DocumentAmountTable.Total("AmountARAP")=0, 
				1, 
				(DocumentAmountTable.Total("AmountARAP")-DocumentAmountTable.Total("AmountVATARAP"))/DocumentAmountTable.Total("AmountARAP"));
			
			AmountARAP = DistributeProportionallyWithZeroSums(DocumentAmountTable.Total("AmountARAP"),
				TableGrouping.UnloadColumn("PayAmount"));
			For Counter = 0 To TableGrouping.Count() - 1 Do
				TableGrouping[Counter].AmountARAP 	= AmountARAP[Counter];
			EndDo;
			
			CurrencyExchangeRateDate = DocumentDataStructure.OccurrenceDate;
			If TypeOf(Document) = Type("DocumentRef.PurchaseAdjustment") Then
				DocumentBasis = Common.ObjectAttributeValue(Document, "DocumentBasis");
				If ValueIsFilled(DocumentBasis) Then
					CurrencyExchangeRateDate = Common.ObjectAttributeValue(DocumentBasis, "Date");
				EndIf;
			EndIf;
			CurrencyExchangeRateUnderContract = DocumentDataStructure.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract;
			
			TotalReducedAmount = 0;
			TotalReducedAmountOfMan = 0;
			TotalReducedLocalSum = 0;
			
			Filter = New Structure("ARAPObject, FinRecordID, ThisIsAdvance");
			Filter.ThisIsAdvance = False;
			AdvancePaymentSelection = New Structure("ARAPObject, PayDate");
			For Each DimensionString In TableGrouping Do;
				
				FillPropertyValues(Filter, DimensionString);
				TablePaymentSchedule = DocumentDataStructure.PaymentSchedule.Copy(Filter, "PayDate, PayAmount, ManPaymentAmount, PaymentAmountLocal");
				PaymentAmounts = TablePaymentSchedule.UnloadColumn("PayAmount");
				AmountsOfManPayments= TablePaymentSchedule.UnloadColumn("ManPaymentAmount");
				LocalPaymentAmounts= TablePaymentSchedule.UnloadColumn("PaymentAmountLocal");
				PaymentDates = TablePaymentSchedule.UnloadColumn("PayDate");
				
				DebtAmountWithoutVAT = 0;
				AmountOfDebtExcludingVATMan = 0;
				AmountOfDebtExcludingVATLocal = 0;
				AdvanceAmount = 0;
				AdvanceAmountOfMan = 0;
				AmountOfSchedAdvance = 0;
				For Counter = 0 To PaymentAmounts.Count() - 1 Do
					AdvancePaymentSelection.ARAPObject = DimensionString.ARAPObject;
					AdvancePaymentSelection.PayDate = PaymentDates[Counter];
					AdvancePaymentLines = TableOfAdvances.FindRows(AdvancePaymentSelection);
					If AdvancePaymentLines.Count() > 0 Then
						AdvanceLine_ = AdvancePaymentLines[0];
						AdvanceAmount = AdvanceAmount + AdvanceLine_.AdvanceAmount * CoefficientOfAmountWithoutVAT;
						AdvanceAmountOfMan = AdvanceAmountOfMan + AdvanceLine_.AdvanceAmountOfMan * CoefficientOfAmountWithoutVAT;
						AmountOfSchedAdvance = AmountOfSchedAdvance + AdvanceLine_.AmountOfSchedAdvance * CoefficientOfAmountWithoutVAT;
						PaymentAmounts[Counter] = PaymentAmounts[Counter] - AdvanceLine_.AdvanceAmount;
						AmountsOfManPayments[Counter] = AmountsOfManPayments[Counter] - AdvanceLine_.AdvanceAmountOfMan;
						LocalPaymentAmounts[Counter] = LocalPaymentAmounts[Counter] - AdvanceLine_.AmountOfSchedAdvance;
					EndIf;
					PaymentAmounts[Counter] = PaymentAmounts[Counter] * CoefficientOfAmountWithoutVAT;
					AmountsOfManPayments[Counter] = AmountsOfManPayments[Counter] * CoefficientOfAmountWithoutVAT;
					LocalPaymentAmounts[Counter] = LocalPaymentAmounts[Counter] * CoefficientOfAmountWithoutVAT;
					DebtAmountWithoutVAT = DebtAmountWithoutVAT + PaymentAmounts[Counter];
					AmountOfDebtExcludingVATMan = AmountOfDebtExcludingVATMan + AmountsOfManPayments[Counter];
					AmountOfDebtExcludingVATLocal = AmountOfDebtExcludingVATLocal + LocalPaymentAmounts[Counter];
				EndDo;
				
				AmountReduced = PresentValueOfPayments(DocumentDataStructure.DiscountRate/100,
					PaymentDates,
					PaymentAmounts,
					DocumentDataStructure.OccurrenceDate); 
				
				LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DocumentDataStructure.Organization);
				ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
				If CurrencyExchangeRateUnderContract And ManagementAccountingCurrency = DocumentDataStructure.Currency Then
					ManSExchangeRate = ProcessingOfExchangeRatesTM.GetContractCurrencyExchangeRateFromCache(
						DocumentDataStructure.Contract,
						CurrencyExchangeRateDate,
						ContractExchangeRateCache);
				Else
					ManSExchangeRate = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(ManagementAccountingCurrency, 
						CurrencyExchangeRateDate,
						CurrencyExchangeRateCache,
						LocalAccountingCurrency);
				EndIf;
				If CurrencyExchangeRateUnderContract Then
					MutualSettlementsExchangeRate = ProcessingOfExchangeRatesTM.GetContractCurrencyExchangeRateFromCache(
						DocumentDataStructure.Contract,
						CurrencyExchangeRateDate,
						ContractExchangeRateCache);
				Else
					MutualSettlementsExchangeRate = ProcessingOfExchangeRatesTM.GetCurrencyExchangeRateFromCache(DocumentDataStructure.Currency, 
						CurrencyExchangeRateDate, 
						CurrencyExchangeRateCache, 
						LocalAccountingCurrency);
				EndIf;
				
				ReducedLocalSum = Round(AmountReduced * MutualSettlementsExchangeRate, 2);
				ReducedAmountOfMan = Round(?(ManSExchangeRate = 0, 0, AmountReduced*MutualSettlementsExchangeRate/ManSExchangeRate), 2);
				
				NewRow = ResultTable1.Add();
				FillPropertyValues(NewRow, DimensionString);
				NewRow.DiscountingAmount = DebtAmountWithoutVAT - AmountReduced;
				NewRow.DiscountingAmountMan = Round(?(ManSExchangeRate = 0, 0, NewRow.DiscountingAmount*MutualSettlementsExchangeRate/ManSExchangeRate), 2);
				NewRow.DiscountingAmountCompl = Round(NewRow.DiscountingAmount * MutualSettlementsExchangeRate, 2);
				
				NewRow.ActualDebtWithoutVAT = DebtAmountWithoutVAT;
				NewRow.DiscountedDebtWithoutVAT = AmountReduced;
				NewRow.CalculatedInterestBalance = DebtAmountWithoutVAT - AmountReduced;
				
				NewRow.ActualDebtWithoutVATCompl = AmountOfDebtExcludingVATLocal;
				NewRow.CalculatedInterestBalanceCompl = AmountOfDebtExcludingVATLocal - ReducedLocalSum;
				NewRow.DiscountedDebtWithoutVATCompl = ReducedLocalSum;
				
				NewRow.ActualDebtWithoutVATMan = AmountOfDebtExcludingVATMan;
				NewRow.CalculatedInterestBalanceMan = AmountOfDebtExcludingVATMan - ReducedAmountOfMan;
				NewRow.DiscountedDebtWithoutVATMan = ReducedAmountOfMan;
				
				TotalReducedAmount = TotalReducedAmount + AmountReduced + AdvanceAmount;
				TotalReducedAmountOfMan = TotalReducedAmountOfMan + ReducedAmountOfMan + AdvanceAmountOfMan;
				TotalReducedLocalSum = TotalReducedLocalSum + ReducedLocalSum + AmountOfSchedAdvance;
				
			EndDo;
			
			DistributionOfReducedAmount = DistributeProportionallyWithZeroSums(TotalReducedAmount, 
				DocumentAmountTable.UnloadColumn("AmountExcludingVAT"));
			
			DistributionOfReducedAmountOfMan = DistributeProportionallyWithZeroSums(TotalReducedAmountOfMan, 
				DocumentAmountTable.UnloadColumn("AmountExcludingVAT"));
			
			DistributionOfReducedLocalSum = DistributeProportionallyWithZeroSums(TotalReducedLocalSum, 
				DocumentAmountTable.UnloadColumn("AmountExcludingVAT"));
			
			For Counter = 0 To DocumentAmountTable.Count() - 1 Do
				AmountGiven = DistributionOfReducedAmount[Counter];
				AmountGivenMan = DistributionOfReducedAmountOfMan[Counter];
				AmountGivenCompl = DistributionOfReducedLocalSum[Counter];
				If DocumentAmountTable[Counter].AmountGiven <> AmountGiven
					Or DocumentAmountTable[Counter].AmountGivenMan <> AmountGivenMan
					Or DocumentAmountTable[Counter].AmountGivenCompl <> AmountGivenCompl Then
						HasChanges = True;
				EndIf;
				DocumentAmountTable[Counter].AmountGiven = DistributionOfReducedAmount[Counter];
				DocumentAmountTable[Counter].AmountGivenMan = DistributionOfReducedAmountOfMan[Counter];
				DocumentAmountTable[Counter].AmountGivenCompl = DistributionOfReducedLocalSum[Counter];
			EndDo;
			
			DiscountingApplied = True;
			
			// To calculate the negative adjustment in the same month:
			AmountOfSettlementsExcludingVAT = DocumentAmountTable.Total("AmountARAP") - DocumentAmountTable.Total("AmountVATARAP");
			DocumentDataStructure.DiscountRate_ = ?(AmountOfSettlementsExcludingVAT=0, 0, TotalReducedAmount / AmountOfSettlementsExcludingVAT);
			
			DocumentDataStructure.PaymentSchedule = ResultTable1;
			
		EndIf;
		
	EndIf;
	
	If Not DiscountingApplied
		And NewOnlineARAPAccounting Then
		
		// Calculation of the negative adjustment discount 
		// The discounting above applies only to a positive adjustment
		// If the positive adjustment is not processed above, then we do not apply discounting
		If TypeOf(Document) = Type("DocumentRef.PurchaseAdjustment") 
			And DocumentAmountTable.Total("AmountARAP") < 0 Then
			
			DocumentAcquisitions = Common.ObjectAttributeValue(Document, "DocumentBasis");
			
			If DataOfPaymentSchedule[DocumentAcquisitions] <> Undefined 
				And DataOfPaymentSchedule[DocumentAcquisitions].Property("DiscountRate_") Then
				DiscountRate_ = DataOfPaymentSchedule[DocumentAcquisitions].DiscountRate_;
			Else
				DiscountRate_ = DocumentDiscountRate(DocumentAcquisitions);
			EndIf;
			
			If Not (DiscountRate_ = 0 Or DiscountRate_ = 1) Then
				
				HasChanges = False;
				For Each RowOfSumTable In DocumentAmountTable Do 
					AmountGiven     = Round(RowOfSumTable.AmountExcludingVAT * DiscountRate_, 2);
					AmountGivenMan  = Round(RowOfSumTable.AmountExcludingVATMan * DiscountRate_, 2);
					AmountGivenCompl = Round(RowOfSumTable.AmountExcludingVATCompl * DiscountRate_, 2);
					If RowOfSumTable.AmountGiven <> AmountGiven
						Or RowOfSumTable.AmountGivenMan <> AmountGivenMan
						Or RowOfSumTable.AmountGivenCompl <> AmountGivenCompl Then
						HasChanges = True;
					EndIf;
					RowOfSumTable.AmountGiven     = AmountGiven;
					RowOfSumTable.AmountGivenMan  = AmountGivenMan;
					RowOfSumTable.AmountGivenCompl = AmountGivenCompl;
				EndDo;
				If Not HasChanges Then
					DocumentDataStructure.Insert("NoDiscountChanges", True);
				EndIf;
				
				DocumentDataStructure = DataOfPaymentSchedule[Document];
				DocumentDataStructure.PaymentSchedule.GroupBy("ARAPObject, FinRecordID", 
					"PayAmount, 
					|ManPaymentAmount, 
					|PaymentAmountLocal, 
					|DiscountingAmount, 
					|DiscountingAmountMan, 
					|DiscountingAmountCompl,
					|ActualDebtWithoutVAT, 
					|DiscountedDebtWithoutVAT, 
					|CalculatedInterestBalance, 
					|ActualDebtWithoutVATCompl, 
					|DiscountedDebtWithoutVATCompl,
					|CalculatedInterestBalanceCompl,
					|ActualDebtWithoutVATMan,
					|DiscountedDebtWithoutVATMan,
					|CalculatedInterestBalanceMan");
				DiscountingAmount 		= DocumentAmountTable.Total("AmountExcludingVAT") - DocumentAmountTable.Total("AmountGiven");
				DiscountingAmountMan 	= DocumentAmountTable.Total("AmountExcludingVATMan") - DocumentAmountTable.Total("AmountGivenMan");
				DiscountingAmountCompl 	= DocumentAmountTable.Total("AmountExcludingVATCompl") - DocumentAmountTable.Total("AmountGivenCompl");
				
				DiscountAmounts 		= DistributeProportionallyWithZeroSums(DiscountingAmount, DocumentDataStructure.PaymentSchedule.UnloadColumn("PayAmount"));
				ManDiscountAmounts 	= DistributeProportionallyWithZeroSums(DiscountingAmountMan, DocumentDataStructure.PaymentSchedule.UnloadColumn("ManPaymentAmount"));
				LocalDiscountAmounts 	= DistributeProportionallyWithZeroSums(DiscountingAmountCompl, DocumentDataStructure.PaymentSchedule.UnloadColumn("PaymentAmountLocal"));
				
				DebtAmountsExcludingVAT 			= DistributeProportionallyWithZeroSums(DocumentAmountTable.Total("AmountExcludingVAT"), DocumentDataStructure.PaymentSchedule.UnloadColumn("PayAmount"));
				DebtAmountsExcludingVATMan 		= DistributeProportionallyWithZeroSums(DocumentAmountTable.Total("AmountExcludingVATMan"), DocumentDataStructure.PaymentSchedule.UnloadColumn("PayAmount"));
				DebtAmountsExcludingVATLocal		= DistributeProportionallyWithZeroSums(DocumentAmountTable.Total("AmountExcludingVATCompl"), DocumentDataStructure.PaymentSchedule.UnloadColumn("PayAmount"));
				
				CoefficientOfAmountWithoutVAT =  ?(DocumentAmountTable.Total("AmountARAP")=0, 
					1, 
					(DocumentAmountTable.Total("AmountARAP")
						- DocumentAmountTable.Total("AmountVATARAP"))
						/ DocumentAmountTable.Total("AmountARAP"));
				
				For Each PlotLine In DocumentDataStructure.PaymentSchedule Do
					
					Balance = GetCurBalancesOfDebtAndInterest(
						DocumentDataStructure.AccountingDimensionByPartners,
						DocumentDataStructure.Currency,
						PlotLine.ARAPObject,
						DocumentDataStructure.ARAPDocument,
						DocumentDataStructure.Period);
					
					PlotLine.DiscountingAmount     = - DiscountAmounts[DocumentDataStructure.PaymentSchedule.IndexOf(PlotLine)];
					PlotLine.DiscountingAmountMan  = - ManDiscountAmounts[DocumentDataStructure.PaymentSchedule.IndexOf(PlotLine)];
					PlotLine.DiscountingAmountCompl = - LocalDiscountAmounts[DocumentDataStructure.PaymentSchedule.IndexOf(PlotLine)];
					
					PlotLine.ActualDebtWithoutVAT 			= Balance.Debt * CoefficientOfAmountWithoutVAT + DebtAmountsExcludingVAT[DocumentDataStructure.PaymentSchedule.IndexOf(PlotLine)];
					PlotLine.CalculatedInterestBalance				= Balance.DiscountingAmount - PlotLine.DiscountingAmount;
					PlotLine.DiscountedDebtWithoutVAT		= PlotLine.ActualDebtWithoutVAT - PlotLine.CalculatedInterestBalance;
					
					PlotLine.ActualDebtWithoutVATMan 		= Balance.ARAPMan * CoefficientOfAmountWithoutVAT + DebtAmountsExcludingVATMan[DocumentDataStructure.PaymentSchedule.IndexOf(PlotLine)];
					PlotLine.CalculatedInterestBalanceMan			= Balance.DiscountingAmountMan - PlotLine.DiscountingAmountMan;
					PlotLine.DiscountedDebtWithoutVATMan	= PlotLine.ActualDebtWithoutVATMan - PlotLine.CalculatedInterestBalanceMan;
					
					PlotLine.ActualDebtWithoutVATCompl 		= Balance.DebtLocal * CoefficientOfAmountWithoutVAT + DebtAmountsExcludingVATLocal[DocumentDataStructure.PaymentSchedule.IndexOf(PlotLine)];
					PlotLine.CalculatedInterestBalanceCompl			= Balance.DiscountingAmountCompl - PlotLine.DiscountingAmountCompl;
					PlotLine.DiscountedDebtWithoutVATCompl	= PlotLine.ActualDebtWithoutVATCompl - PlotLine.CalculatedInterestBalanceCompl;
					
				EndDo;
				
				DiscountingApplied = True;
				
			EndIf;
			
		EndIf;
	EndIf;
	
	If Not DiscountingApplied Then
		For Each RowOfSumTable In DocumentAmountTable Do
			RowOfSumTable.AmountGiven = RowOfSumTable.AmountARAP - RowOfSumTable.AmountVATARAP;
			RowOfSumTable.AmountGivenMan = RowOfSumTable.AmountExcludingVATMan;
			RowOfSumTable.AmountGivenCompl = RowOfSumTable.AmountExcludingVATCompl;
		EndDo;
	EndIf;
	
	Return HasChanges;
	
EndFunction

Function GetCurBalancesOfDebtAndInterest(AccountingDimensionByPartners, Currency, ARAPObject, ARAPDocument, Period)
	
	Query = New Query;
	Query.SetParameter("AccountingDimensionByPartners", AccountingDimensionByPartners);
	Query.SetParameter("Currency", Currency);
	Query.SetParameter("ARAPObject", ARAPObject);
	Query.SetParameter("ARAPDocument", ARAPDocument);
	Query.SetParameter("Period", New Boundary(Period, BoundaryType.Excluding));
	Query.Text = 
		"SELECT
		|	VendorsARAPAccountingByDueDatesBalance.DebtBalance AS Debt,
		|	VendorsARAPAccountingByDueDatesBalance.DebtLocalBalance AS DebtLocal,
		|	VendorsARAPAccountingByDueDatesBalance.ARAPManBalance AS ARAPMan
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(
		|			&Period,
		|			AccountingDimensionByPartners = &AccountingDimensionByPartners
		|				AND Currency = &Currency
		|				AND ARAPObject = &ARAPObject
		|				AND ARAPDocument = &ARAPDocument) AS VendorsARAPAccountingByDueDatesBalance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DiscountInterestExpenseBalance.DiscountingAmountBalance AS DiscountingAmount,
		|	DiscountInterestExpenseBalance.DiscountingAmountComplBalance AS DiscountingAmountCompl,
		|	DiscountInterestExpenseBalance.DiscountingAmountManBalance AS DiscountingAmountMan
		|FROM
		|	AccumulationRegister.DiscountInterestExpense.Balance(
		|			&Period,
		|			AccountingDimensionByPartners = &AccountingDimensionByPartners
		|				AND Currency = &Currency
		|				AND ARAPObject = &ARAPObject
		|				AND ARAPDocument = &ARAPDocument) AS DiscountInterestExpenseBalance";
	QueryResult = Query.ExecuteBatch();
	SampleDebt = QueryResult[0].Select();
	SamplingPercentages = QueryResult[1].Select();
	Result = New Structure;
	Result.Insert("Debt", 0);
	Result.Insert("ARAPMan", 0);
	Result.Insert("DebtLocal", 0);
	Result.Insert("DiscountingAmount", 0);
	Result.Insert("DiscountingAmountMan", 0);
	Result.Insert("DiscountingAmountCompl", 0);
	If SampleDebt.Next() Then
		FillPropertyValues(Result, SampleDebt);
	EndIf;
	If SamplingPercentages.Next() Then
		FillPropertyValues(Result, SamplingPercentages);
	EndIf;
	
	Return Result;
	
EndFunction

Function DocumentDiscountRate(Ref)
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.Text = 
		"SELECT
		|	ISNULL(SUM(DocumentAmountsInAccountingCurrency.AmountGiven), 0) AS AmountGiven,
		|	ISNULL(SUM(DocumentAmountsInAccountingCurrency.AmountARAP - DocumentAmountsInAccountingCurrency.AmountVATARAP), 0) AS AmountExcludingVAT
		|FROM
		|	InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
		|WHERE
		|	DocumentAmountsInAccountingCurrency.Recorder = &Ref";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return ?(Selection.AmountExcludingVAT = 0, 0, Selection.AmountGiven / Selection.AmountExcludingVAT);
	Else 
		Return 0;
	EndIf;
EndFunction

Procedure RecordRegisteredRecordsInInterestExpenseDiscounting(DataOfPaymentSchedule, Document, WritingRequired = True)
	
	If DataOfPaymentSchedule <> Undefined And DataOfPaymentSchedule[Document] <> Undefined Then
		
		DocumentDataStructure =  DataOfPaymentSchedule[Document];
		RecordSet = AccumulationRegisters.DiscountInterestExpense.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(Document);
		If Not (DocumentDataStructure.Property("Clear_InterestAccrual")
			And DocumentDataStructure.Clear_InterestAccrual) Then
			For Each PlotLine In DocumentDataStructure.PaymentSchedule Do
				If PlotLine.DiscountingAmount = 0 
					And PlotLine.DiscountingAmountMan = 0 
					And PlotLine.DiscountingAmountCompl = 0 
					And PlotLine.DiscountedDebtWithoutVAT = 0 
					And PlotLine.DiscountedDebtWithoutVATMan = 0 
					And PlotLine.DiscountedDebtWithoutVATCompl = 0 Then
					// There is no Discounted debt and there is no change in debt - discounting is disabled, there is no need to make a record
					Continue;
				EndIf;
				If DocumentDataStructure.ThisIsNegativeAdjustment Then
					MovementInterestAccrual = RecordSet.AddExpense();
				Else
					MovementInterestAccrual = RecordSet.AddReceipt();
				EndIf;
				FillPropertyValues(MovementInterestAccrual, PlotLine);
				FillPropertyValues(MovementInterestAccrual, DocumentDataStructure);
			EndDo;
		EndIf;
		
		If DocumentDataStructure.ThisIsNegativeAdjustment Then
			If DocumentDataStructure.ThereAreRegisterRecordsOfDiscounting Then
				If DocumentDataStructure.Property("NoDiscountChanges")
					And DocumentDataStructure.NoDiscountChanges Then
					// The movements of the negative adjustment do not change
					WritingRequired = False;
				EndIf;
			ElsIf RecordSet.Count() = 0 Then
				// There were no movements and did not appear - no recording is required
				WritingRequired = False;
			EndIf;
		EndIf;
		If WritingRequired Then
			RecordSet.Write();
		EndIf;
		
	EndIf;
	
EndProcedure

Function DistributeProportionallyWithZeroSums(InitialAmount_, ArrayOfCoefficients)
	CoefficientsSum = 0;
	For Counter = 0 To ArrayOfCoefficients.Count() - 1 Do
		CoefficientsSum = CoefficientsSum + ArrayOfCoefficients[Counter];
	EndDo;
	If InitialAmount_ = 0 Or CoefficientsSum = 0 Then
		Result = New Array;
		For Counter = 0 To ArrayOfCoefficients.Count() - 1 Do
			Result.Add(0);
		EndDo;
	Else
		Result = TMCommonUseClientServer.DistributeProportionally(InitialAmount_, ArrayOfCoefficients);
	EndIf; 
	Return Result;
EndFunction

// Parameters for calculating document discounting.
// 
// Parameters:
//  DocumentsArray - Array of DocumentRef - array of documents
// 
// Returns:
//  Structure - Parameters For Calculating Document Discounting:
// * SelectionByDocuments - QueryResultSelection - Document Data
// * DataOfPaymentSchedule - See PaymentSchedulesForDiscounting
// * CurrencyExchangeRateCache - See ProcessingOfExchangeRatesTM.InitializeCurrencyExchangeRateCache
// * ContractExchangeRateCache - See ProcessingOfExchangeRatesTM.InitializeCacheOfContractExchangeRates
//
Function ParametersForCalculatingDocumentDiscounting(DocumentsArray) Export
	
	DocumentsToBeRecalculated = New Array;
	DataOfPaymentSchedule = PaymentSchedulesForDiscounting(DocumentsArray, "VendorsARAPAccounting", DocumentsToBeRecalculated);
	CurrencyExchangeRateCache = ProcessingOfExchangeRatesTM.InitializeCurrencyExchangeRateCache();
	ContractExchangeRateCache = ProcessingOfExchangeRatesTM.InitializeCacheOfContractExchangeRates();
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	RegisterData.Recorder AS Recorder,
		|	RegisterData.Period AS Period
		|INTO DocumentsTable
		|FROM
		|	InformationRegister.DocumentAmountsInAccountingCurrency AS RegisterData
		|WHERE
		|	RegisterData.Recorder IN(&DocumentsArray)
		|
		|INDEX BY
		|	Recorder,
		|	Period
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentAmountsInAccountingCurrency.Active AS Active,
		|	DocumentAmountsInAccountingCurrency.Period AS Period,
		|	DocumentAmountsInAccountingCurrency.Recorder AS Ref,
		|	DocumentAmountsInAccountingCurrency.RowID AS RowID,
		|	DocumentAmountsInAccountingCurrency.AmountExcludingVAT AS AmountExcludingVAT,
		|	DocumentAmountsInAccountingCurrency.VATAmount AS VATAmount,
		|	DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl AS AmountExcludingVATCompl,
		|	DocumentAmountsInAccountingCurrency.VATBaseLocal AS VATBaseLocal,
		|	DocumentAmountsInAccountingCurrency.VATAmountCompl AS VATAmountCompl,
		|	DocumentAmountsInAccountingCurrency.AmountExcludingVATMan AS AmountExcludingVATMan,
		|	DocumentAmountsInAccountingCurrency.VATAmountMan AS VATAmountMan,
		|	DocumentAmountsInAccountingCurrency.AmountARAP AS AmountARAP,
		|	DocumentAmountsInAccountingCurrency.AmountVATARAP AS AmountVATARAP,
		|	DocumentAmountsInAccountingCurrency.AmountGiven AS AmountGiven,
		|	DocumentAmountsInAccountingCurrency.AmountGivenMan AS AmountGivenMan,
		|	DocumentAmountsInAccountingCurrency.AmountGivenCompl AS AmountGivenCompl,
		|	DocumentAmountsInAccountingCurrency.Currency AS Currency,
		|	DocumentAmountsInAccountingCurrency.ARAPCurrency AS ARAPCurrency,
		|	DocumentAmountsInAccountingCurrency.VATRate AS VATRate,
		|	DocumentAmountsInAccountingCurrency.VATBasePeriod AS VATBasePeriod,
		|	DocumentAmountsInAccountingCurrency.RecordedInARAPAccounting AS RecordedInARAPAccounting,
		|	DocumentAmountsInAccountingCurrency.ARAPObject AS ARAPObject,
		|	DocumentAmountsInAccountingCurrency.RecalculateBasedOnARAPData AS RecalculateBasedOnARAPData,
		|	DocumentAmountsInAccountingCurrency.PaymentType_ AS PaymentType_,
		|	CASE
		|		WHEN VALUETYPE(DocumentAmountsInAccountingCurrency.Recorder) = TYPE(Document.PurchaseAdjustment)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ThisIsAcquisitionAdjustment
		|FROM
		|	InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
		|		INNER JOIN DocumentsTable AS DocumentsTable
		|		ON DocumentAmountsInAccountingCurrency.Period = DocumentsTable.Period
		|			AND DocumentAmountsInAccountingCurrency.Recorder = DocumentsTable.Recorder
		|
		|ORDER BY
		|	ThisIsAcquisitionAdjustment
		|TOTALS BY
		|	Ref
		|"; 
	Query.SetParameter("DocumentsArray", DocumentsToBeRecalculated);
	SetPrivilegedMode(True);
	SelectionByDocument = Query.Execute().Select(QueryResultIteration.ByGroups);
	SetPrivilegedMode(False);
	
	ParametersForCalculation = New Structure;
	ParametersForCalculation.Insert("SelectionByDocuments", SelectionByDocument);
	ParametersForCalculation.Insert("DataOfPaymentSchedule", DataOfPaymentSchedule);
	ParametersForCalculation.Insert("CurrencyExchangeRateCache", CurrencyExchangeRateCache);
	ParametersForCalculation.Insert("ContractExchangeRateCache", ContractExchangeRateCache);
	
	Return ParametersForCalculation;
	
EndFunction

// Calculate discounting by document.
// 
// Parameters:
//  DataByDocument - QueryResultSelection - Document Data
//  DiscountCalculationParameters - See ParametersForCalculatingDocumentDiscounting
//  DocumentAmountTable - Undefined, ValueTable - Document Amount Table
//  DocumentsToBeRecalculated - Undefined, Array of DocumentRef - Documents To Be Recalculated
//
Procedure CalculateDiscountingByDocument(DataByDocument, DiscountCalculationParameters, DocumentAmountTable = Undefined, DocumentsToBeRecalculated = Undefined) Export
	
	If DocumentAmountTable = Undefined Then
		DocumentAmountTable = CreateRecordSet().UnloadColumns();
	EndIf;
	
	If DocumentsToBeRecalculated = Undefined Then
		DocumentsToBeRecalculated = New Array;
	EndIf;
	
	Selection = DataByDocument.Select();

	While Selection.Next() Do

		Record = DocumentAmountTable.Add();
		FillPropertyValues(Record, Selection);

	EndDo;

	HasChanges = ListDocumentAmounts(DiscountCalculationParameters.DataOfPaymentSchedule, DocumentAmountTable, DiscountCalculationParameters.CurrencyExchangeRateCache,
		DiscountCalculationParameters.ContractExchangeRateCache, DataByDocument.Ref);
	RecordRegisteredRecordsInInterestExpenseDiscounting(DiscountCalculationParameters.DataOfPaymentSchedule, DataByDocument.Ref, HasChanges);
	If HasChanges Then
		RecordSet = CreateRecordSet();
		RecordSet.Filter.Recorder.Set(DataByDocument.Ref);
		RecordSet.Load(DocumentAmountTable);
		RecordSet.AdditionalProperties.Insert("UpdateDocumentAmountsInAccountingCurrencies");
		RecordSet.Write();
		DocumentsToBeRecalculated.Add(DataByDocument.Ref);
	EndIf;

	DocumentAmountTable.Clear();
	
EndProcedure


#EndRegion

// With the operational distribution of mutual settlements and the use of the "Medium-sliding" method of estimating the value of goods, the
// amount of the document in accounting currencies must be calculated in the transaction of the document.
// 
// Parameters:
//  Document - DocumentObject - current document
// 
// Returns:
//  Boolean - To calculate the amounts in the currencies of the account in the transaction of the document
Function ToCalculateAmountsInTransactionOfDocument(Document)
	
	CalculateDocumentAmountsInTransaction = False;
	
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");

	If NewOnlineARAPAccounting And Not Document.DataExchange.Load Then
		
		PropertiesOfRegisteredRecordsOfMechanisms = Document.AdditionalProperties.DocumentsPosting.PropertiesOfRegisteredRecordsOfMechanisms;

		If PropertiesOfRegisteredRecordsOfMechanisms.Property("ARAPAccounting") 
			And PropertiesOfRegisteredRecordsOfMechanisms.ARAPAccounting.Property("PerformDistributionOfMutualSettlementsInTransaction") Then
			PerformDistributionOfMutualSettlementsInTransaction = PropertiesOfRegisteredRecordsOfMechanisms.ARAPAccounting.PerformDistributionOfMutualSettlementsInTransaction;
		Else
			PerformDistributionOfMutualSettlementsInTransaction = Not OnlineARAPAccountingServer.AllocateARAPInBackgroundJob();
		EndIf;
		
		If PerformDistributionOfMutualSettlementsInTransaction Then
			
			// Get a table with organizations and periods
			Query = New Query;
			Query.Text = "
			|SELECT DISTINCT
			|	BEGINOFPERIOD(Jobs.TaskPeriod, MONTH) AS Period,
			|	Jobs.Organization AS Organization
			|FROM
			|	InformationRegister.JobsOfBackdateAdditionalDocumentPosting AS Jobs
			|WHERE
			|	Jobs.JobKind = VALUE(Catalog.BackdateJobKinds.UpdateDocumentAmountsInAccountingCurrencies)
			|	AND Jobs.Document = &Document";
			Query.SetParameter("Document", Document.Ref);
			SetPrivilegedMode(True);
			Selection = Query.Execute().Select();
			SetPrivilegedMode(False);
			While Selection.Next() Do

				AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
					"FinancialAccountingPolicy", Selection.Organization, Selection.Period);

				If AccountingPolicyParameters <> Undefined 
					And AccountingPolicyParameters.InventoryValuationMethod = Enums.InventoryValuationMethods.MovingAverage Then
					
					CalculateDocumentAmountsInTransaction = True;
					Break;
					
				EndIf;

			EndDo;
			
		EndIf;
		
	EndIf;
	
	Return CalculateDocumentAmountsInTransaction;
	
EndFunction

// Performs a search for problematic documents for which the amounts in accounting currencies do not match the Register Records on the registers of mutual settlements, 
// places the found registrars in the temporary table "Problematic documents Sum up accounting currencies".
// 
// The search for problematic documents is performed according to the list of organizations in the closing period, which is set in the parameters for closing the month.
// For each organization, periods in which the month closing of operation has already been completed
// according to the stage "Formation of Registered Records for settlements with partners and reassessment of settlements" are excluded from the audit.
// 
// Parameters:
//  TemporaryTablesForCheckingDiscrepancies - TempTablesManager - Contains temporary tables with checks for discrepancies. The 
//  temporary tables manager should have a table "Closing Time Period" with data on unclosed periods of operation for closing the month.
//  EndOfClosingPeriod - Date - The end of the closing period specified in the month's closing parameters.
Procedure FindRecordersWithDiscrepanciesInMovementsOfAmountsInAccountingCurrenciesAndSettlementRegisters(TemporaryTablesForCheckingDiscrepancies, EndOfClosingPeriod) Export
	
	Query = New Query;
	Query.TempTablesManager = TemporaryTablesForCheckingDiscrepancies;
	Query.SetParameter("EndOfPeriod", EndOfClosingPeriod);
	Query.Text = "
	|SELECT DISTINCT
	|	CustomersARAPAccounting.Recorder AS Recorder,
	|	CustomersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CustomersARAPAccounting.Period AS Period
	|INTO RecordersOfSettlementRegisters
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|		INNER JOIN TT_PeriodsOfClosing AS TT_PeriodsOfClosing
	|		ON CustomersARAPAccounting.Period >= TT_PeriodsOfClosing.Month
	|		AND CustomersARAPAccounting.Period <= &EndOfPeriod
	|		AND CustomersARAPAccounting.AccountingDimensionByPartners.Organization = TT_PeriodsOfClosing.Organization
	|WHERE
	|	CustomersARAPAccounting.Active
	|	AND CustomersARAPAccounting.AccountingDimensionByPartners.Organization IN
	|		(SELECT
	|			TT.Organization
	|		FROM
	|			TT_PeriodsOfClosing AS TT)
	|	AND CustomersARAPAccounting.Sum <> 0
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VendorsARAPAccounting.Recorder AS Recorder,
	|	VendorsARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccounting.Period AS Period
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|		INNER JOIN TT_PeriodsOfClosing AS TT_PeriodsOfClosing
	|		ON VendorsARAPAccounting.Period >= TT_PeriodsOfClosing.Month
	|		AND VendorsARAPAccounting.Period <= &EndOfPeriod
	|		AND VendorsARAPAccounting.AccountingDimensionByPartners.Organization = TT_PeriodsOfClosing.Organization
	|WHERE
	|	VendorsARAPAccounting.Active
	|	AND VendorsARAPAccounting.AccountingDimensionByPartners.Organization IN
	|		(SELECT
	|			TT.Organization
	|		FROM
	|			TT_PeriodsOfClosing AS TT)
	|	AND VendorsARAPAccounting.Sum <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Calculations.Recorder AS DocumentRecorder
	|FROM
	|	RecordersOfSettlementRegisters AS Calculations
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RecordersOfSettlementRegisters";
	
	RecordersList = Query.Execute().Unload().UnloadColumn("DocumentRecorder");

	RequestProblematicDocuments = New Query;
	RequestProblematicDocuments.Text = TextOfRequestForDocumentsToBeRecalculated();
	RequestProblematicDocuments.SetParameter("DocumentsArray", RecordersList);
	RequestProblematicDocuments.SetParameter("ThisIsTest", True);
	RequestProblematicDocuments.SetParameter("CurrencyOfManAccounting", Constants.ManagementAccountingCurrency.Get());
	RequestProblematicDocuments.SetParameter("NewOnlineARAPAccounting", True);
	RequestProblematicDocuments.SetParameter("AccordingToAllDocuments", False);

	ProblematicDocuments = RequestProblematicDocuments.Execute().Unload().UnloadColumn("ARAPDocument");
	
	Query = New Query;
	Query.TempTablesManager = TemporaryTablesForCheckingDiscrepancies;
	Query.SetParameter("RecordersList", ProblematicDocuments);
	Query.Text = "
	|SELECT DISTINCT
	|	DocumentsRegistry.Ref AS Recorder,
	|	DocumentsRegistry.Organization AS Organization
	|INTO ProblematicDocumentsAmountsInAccountingCurrencies
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.Organization IN
	|		(SELECT
	|			TT.Organization
	|		FROM
	|			TT_PeriodsOfClosing AS TT)
	|	AND DocumentsRegistry.Ref IN (&RecordersList)";
	
	Query.Execute();
	
EndProcedure

#EndRegion

#EndIf
