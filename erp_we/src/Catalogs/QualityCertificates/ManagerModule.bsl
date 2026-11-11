#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a list of registered certificate types
//
// Returns:
//   Array   - an array containing certificate types.
//
Function CreateListToSelectCertificateTypes() Export
		
	CertificateTypeTable = New ValueTable;
	CertificateTypeTable.Columns.Add("CertificateType", New TypeDescription("String",,New StringQualifiers(50)));
	NewRow = CertificateTypeTable.Add();
	NewRow.CertificateType = NStr("vi = 'Giấy chứng nhận phù hợp';
									|ru = 'Сертификат соответствия';
									|en = 'Certificate of conformity'; fa = 'Certificate of conformity';
									|it = 'Certificato di conformità';
									|pl = 'Certyfikat zgodności';
									|tr = 'Uygunluk sertifikası'");
	NewRow = CertificateTypeTable.Add();
	NewRow.CertificateType = NStr("vi = 'Giấy chứng nhận vệ sinh dịch tễ';
									|ru = 'Гигиенический сертификат';
									|en = 'Hygienic certificate'; fa = 'گواهی بهداشتی';
									|it = 'Certificato igienico';
									|pl = 'Certyfikat higieniczny/świadectwo sanitarno epidemiologiczne';
									|tr = 'Hijyen sertifikası'");
	NewRow = CertificateTypeTable.Add();
	NewRow.CertificateType = NStr("vi = 'Giấy chứng nhận an toàn cháy nổ';
									|ru = 'Пожарный сертификат';
									|en = 'Fire certificate'; fa = 'Fire certificate';
									|it = 'Certificato antincendio';
									|pl = 'Certyfikat pożarowy';
									|tr = 'Yangın sertifikası'");
	NewRow = CertificateTypeTable.Add();
	NewRow.CertificateType = NStr("vi = 'Tờ khai phù hợp';
									|ru = 'Декларация о соответствии';
									|en = 'Declaration of conformity'; fa = 'Declaration of conformity';
									|it = 'Dichiarazione di conformità';
									|pl = 'Deklaracja zgodności';
									|tr = 'Uygunluk beyannamesi'");
	
	Query = New Query;	
	Query.Text = 
	"SELECT
	|	CertificateTypeTable.CertificateType AS CertificateType
	|INTO TableOfPredefinedTypes
	|FROM
	|	&CertificateTypeTable AS CertificateTypeTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	QualityCertificates.CertificateType AS CertificateType
	|FROM
	|	Catalog.QualityCertificates AS QualityCertificates
	|WHERE
	|	QualityCertificates.IsFolder = FALSE
	|
	|UNION
	|
	|SELECT
	|	TableOfPredefinedTypes.CertificateType
	|FROM
	|	TableOfPredefinedTypes AS TableOfPredefinedTypes
	|
	|ORDER BY
	|	CertificateType";
	
	Query.SetParameter("CertificateTypeTable",CertificateTypeTable);
	
	Return Query.Execute().Unload().UnloadColumn("CertificateType");
	
EndFunction

// Generates a list of certificate types that match the search parameters
//
// Parameters:
//  Text	 - String - the text of the search.
// 
// Returns:
//  Array - an array containing certificate types.
//
Function AutomaticSelectionOfCertificateTypes(Text = "") Export
	
	Query = New Query;	
	Query.Text = 
	"SELECT DISTINCT
	|	QualityCertificates.CertificateType AS CertificateType
	|FROM
	|	Catalog.QualityCertificates AS QualityCertificates
	|WHERE
	|	QualityCertificates.IsFolder = FALSE" +
	?(ValueIsFilled(Text),	" AND QualityCertificates.CertificateType LIKE &Text ","") +"
	|
	|ORDER BY
	|	CertificateType";
	Query.SetParameter("Text",Text);
	Return Query.Execute().Unload().UnloadColumn("CertificateType");
	
EndFunction

// Sets the Status value of the certificates of the item and returns information about the data processing.
//
// Parameters:
//	FillParameters - See ProductsClientServer.ParametersForSettingStatusOfCertificatesOfDefaultNomenclature.
//
// Returns:
//	Structure - a collection of information about the result of data processing containing the following properties:
//		* AmountOfDataToBeProcessed - Number - the amount of data that needed to be processed.
//		* NumberOfChangedData - Number - the amount of data that could be processed.
//		* Status - EnumRef.StatusesOfQualityCertificates - the set Status value.
//
Function SetStatusOfNomenclatureCertificates(FillParameters) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
						"Catalog.QualityCertificates.ManagerModule.SetStatusOfNomenclatureCertificates");
	
	AmountOfDataToBeProcessed	= 0;
	CertificatesList			= New Array;
	ModifiedCertificates		= New Array;
	
	ProductsLocalization.AddParametersForSettingStatusOfNomenclatureCertificates(FillParameters);
	
	For Each ProcessedString In FillParameters.DataForProcessing_ Do
		
		If TypeOf(ProcessedString) = Type("InformationRegisterRecordKey.QualityCertificateApplicationAreas") Then
			CertificateBeingProcessed = ProcessedString.QualityCertificate;
			
			If CertificatesList.Find(CertificateBeingProcessed) = Undefined Then
				CertificatesList.Add(CertificateBeingProcessed);
				
				AmountOfDataToBeProcessed = AmountOfDataToBeProcessed + 1;
			Else
				Continue;
			EndIf;
		ElsIf TypeOf(ProcessedString) = Type("CatalogRef.QualityCertificates") Then
			CertificateBeingProcessed = ProcessedString;
			
			AmountOfDataToBeProcessed = AmountOfDataToBeProcessed + 1;
		Else
			Continue;
		EndIf;
		
		ProcessObject = True;
		CertificateObject = CertificateBeingProcessed.GetObject();
		
		Try
			CertificateObject.Lock();
		Except
			ProcessObject = False;
			EventName = NStr("vi = 'Thay đổi trạng thái chứng nhận mặt hàng';
							|ru = 'Изменение статусов сертификатов номенклатуры';
							|en = 'Change quality certificate statuses'; fa = 'Change quality certificate statuses';
							|it = 'Изменение статусов сертификатов номенклатуры';
							|pl = 'Change quality certificate statuses';
							|tr = 'Kalite belgeleri durumlarını düzenle'", Common.DefaultLanguageCode());
			
			MessageText = NStr("vi = 'Không thể xử lý đối tượng: %1 do nguyên nhân: %2';
								|ru = 'Не удалось обработать объект: ""%1"" по причине: %2';
								|en = 'Couldn''t process object: ""%1"". Reason: %2'; fa = 'Couldn''t process object: ""%1"". Reason: %2';
								|it = 'Не удалось обработать объект: ""%1"" по причине: %2';
								|pl = 'Couldn''t process object: ""%1"". Reason: %2';
								|tr = 'Nesne işlenemedi: ""%1"" sebep: %2'");
			MessageText = StrTemplate(MessageText,
										String(CertificateBeingProcessed),
										ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(EventName,
									EventLogLevel.Warning,
									CertificateBeingProcessed.Metadata(),
									CertificateBeingProcessed,
									MessageText);
		EndTry;
		
		If ProcessObject
			And CertificateObject.IsFolder Then
			
			ProcessObject = False;
			
			MessageText = NStr("vi = 'Khôn cần đặt trạng thái cho nhóm ""%1""';
								|ru = 'Установка статуса для группы ""%1"" не требуется';
								|en = 'Setting the status for the ""%1"" group is not required'; fa = 'Setting the status for the ""%1"" group is not required';
								|it = 'Setting the status for the ""%1"" group is not required';
								|pl = 'Setting the status for the ""%1"" group is not required';
								|tr = '""%1"" grubu için durum ayarlaması gerekli değildir'");
			MessageText = StrTemplate(MessageText, String(CertificateBeingProcessed));
			
			Common.MessageToUser(MessageText, CertificateBeingProcessed);
			
		EndIf;
		
		ProductsLocalization.SetStatusOfNomenclatureCertificates(CertificateObject,
																		FillParameters,
																		ProcessObject);
		
		If ProcessObject
			And CertificateObject.Status = FillParameters.Status Then
			
			ProcessObject = False;
			
			MessageText = NStr("vi = 'Chưa thay đổi trạng thái chứng thư ""%1"", bởi vì chứng thư nằm ở trạng thái ""%2""';
								|ru = 'Статус сертификата ""%1"" не изменен, т.к. сертификат уже находится в статусе ""%2""';
								|en = 'The ""%1"" certificate status is not changed as the certificate is already in the ""%2"" status'; fa = 'The ""%1"" certificate status is not changed as the certificate is already in the ""%2"" status';
								|it = 'Статус сертификата ""%1"" не изменен, т.к. сертификат уже находится в статусе ""%2""';
								|pl = 'The ""%1"" certificate status is not changed as the certificate is already in the ""%2"" status';
								|tr = 'Belge zaten ""%2"" durumunda olduğu için ""%1"" Belge durumu değiştirilmedi'");
			MessageText = StrTemplate(MessageText,
										String(CertificateBeingProcessed),
										String(FillParameters.Status));
			
			Common.MessageToUser(MessageText, CertificateBeingProcessed);
			
		EndIf;
		
		If Not ProcessObject Then
			Continue;
		EndIf;
		
		CertificateObject.Status = FillParameters.Status;
		
		Try
			CertificateObject.Write();
			
			ModifiedCertificates.Add(CertificateBeingProcessed);
		Except
			Common.MessageToUser(ErrorProcessing.BriefErrorDescription(ErrorInfo()),
													CertificateBeingProcessed);
		EndTry;
		
	EndDo;
	
	NumberOfChangedData = ModifiedCertificates.Count();
	
	ProcessingResult = New Structure;
	ProcessingResult.Insert("AmountOfDataToBeProcessed",	AmountOfDataToBeProcessed);
	ProcessingResult.Insert("NumberOfChangedData",	NumberOfChangedData);
	ProcessingResult.Insert("Status",						FillParameters.Status);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, AmountOfDataToBeProcessed);
	
	Return ProcessingResult;
	
EndFunction

// Returns an array of certificates of the item type for the document.
//
// Parameters:
//	ObjectsArray - Array of DocumentRef - Documents.
//
// Returns:
//	Array of CatalogRef.QualityCertificates - certificates of the nomenclature according to the document.
//
Function DocumentNomenclatureCertificates(ObjectsArray) Export
	
	SetPrivilegedMode(True);
	
	QualityCertificates = New Array;
	
	If TypeOf(ObjectsArray[0]) = Type("DocumentRef.TransportationJob") Then
		Query = New Query;
		Query.Text = TextOfRequestToGetListOfInvoicesFromTransportationTasks();
		Query.SetParameter("TransportationJobs",ObjectsArray);
		ArrayOfObjectsToRequest = Query.Execute().Unload().UnloadColumn("ReferenceOrder");
	Else
		ArrayOfObjectsToRequest = ObjectsArray;
	EndIf;
	
	Query = New Query;
	Query.Text = TextOfRequestForCertificatesOfDocumentProductRange() + "
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsWithCertificates.QualityCertificate AS QualityCertificate,
	|	ProductsWithCertificates.CertificateType AS CertificateType,
	|	ProductsWithCertificates.CertificatePriority AS CertificatePriority,
	|	ProductsWithCertificates.StatusOfRAC AS StatusOfRAC,
	|	ProductsWithCertificates.UpdateDateOfRACStatus AS UpdateDateOfRACStatus
	|FROM
	|	DocumentGoods AS DocumentGoods
	|		LEFT JOIN ProductsWithCertificates AS ProductsWithCertificates
	|		ON DocumentGoods.Products = ProductsWithCertificates.Products
	|		AND DocumentGoods.Characteristic = ProductsWithCertificates.Characteristic
	|		AND DocumentGoods.Series = ProductsWithCertificates.Series
	|		AND DocumentGoods.Date >= ProductsWithCertificates.StartOfValidityPeriod
	|		AND DocumentGoods.Date <= ProductsWithCertificates.Expiration
	|WHERE
	|	DocumentGoods.Products.KeepRecordsOfQualityCertificates = TRUE
	|		AND NOT ProductsWithCertificates.QualityCertificate IS NULL
	|	
	|GROUP BY
	|	ProductsWithCertificates.QualityCertificate,
	|	ProductsWithCertificates.CertificateType,
	|	ProductsWithCertificates.CertificatePriority,
	|	ProductsWithCertificates.StatusOfRAC,
	|	ProductsWithCertificates.UpdateDateOfRACStatus";
	
	Query.SetParameter("ObjectsArray", ArrayOfObjectsToRequest);
	
	ResultsArray = Query.ExecuteBatch();
	NumberOfResults = ResultsArray.Count();
	
	QueryResult = ResultsArray[NumberOfResults - 1]; // QueryResult
	SelectionByDocuments = QueryResult.Select();
	
	While SelectionByDocuments.Next() Do
		QualityCertificates.Add(SelectionByDocuments.QualityCertificate);
	EndDo;
	
	Return QualityCertificates;
	
EndFunction

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndIf

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Images of Nomenclature certificates
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "Catalog.QualityCertificates";
	PrintCommand.Id = "ImageProductCertificates";
	PrintCommand.Presentation = NStr("vi = 'Hình ảnh giấy chứng nhận';
									|ru = 'Изображения сертификатов';
									|en = 'Certificate images'; fa = 'تصاویر گواهی';
									|it = 'Visualizzazione dei certificati';
									|pl = 'Obrazy certyfikatu';
									|tr = 'Sertifika resmi'");

EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array    - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - value - the object reference;
//                                            view - name of the area where the object was output (output parameter);
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ImageProductCertificates") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ImageProductCertificates",
			NStr("vi = 'Hình ảnh giấy chứng nhận';
				|ru = 'Изображения сертификатов';
				|en = 'Certificate images'; fa = 'تصاویر گواهی';
				|it = 'Visualizzazione dei certificati';
				|pl = 'Obrazy certyfikatu';
				|tr = 'Sertifika resmi'"),
			ToFormPrintedFormOfImageOfCertificates(ObjectsArray, PrintObjects),
			,
			"Catalog.QualityCertificates.PF_MXL_CertificateImages");
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

// The function receives data for the formation of a printed form "Certificates of nomenclature (registry)".
//
// Parameters:
//  ObjectsArray  - array of print objects;
//  PrintObjects   - print objects;
//
// Returns:
//   SpreadsheetDocument   - the generated tabular document.
//
Function CreatePrintedFormRegisterOfProductCertificates(ObjectsArray, PrintObjects) Export
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PrintPARAMETERS_ProductCertificates_CertificateRegistry";
	
	If TypeOf(ObjectsArray[0]) = Type("DocumentRef.TransportationJob") Then
		Query = New Query;
		Query.Text = TextOfRequestToGetListOfInvoicesFromTransportationTasks();
		Query.SetParameter("TransportationJobs",ObjectsArray);
		ArrayOfObjectsToRequest = Query.Execute().Unload().UnloadColumn("ReferenceOrder");
	Else
		ArrayOfObjectsToRequest = ObjectsArray;
	EndIf;
	
	Query = New Query;
	Query.Text = TextOfRequestForCertificatesOfDocumentProductRange() + "
	|//////////////////////////////////////////////////////////////////////////////// 10
	|SELECT
	|	DocumentsAccountingCertificates.Ref AS Ref,
	|	DocumentsAccountingCertificates.KeepRecordsOfQualityCertificates AS KeepRecordsOfQualityCertificates
	|FROM
	|	DocumentsAccountingCertificates AS DocumentsAccountingCertificates
	|WHERE
	|	NOT DocumentsAccountingCertificates.KeepRecordsOfQualityCertificates
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 11
	|SELECT
	|	AllDocuments.Ref AS Ref,
	|	PRESENTATION(AllDocuments.Ref) AS RepresentationOfTheReference,
	|	PRESENTATION(AllDocuments.BusinessOperation) AS PresentationOfBusinessTransaction
	|FROM
	|	AllDocuments AS AllDocuments
	|WHERE
	|	AllDocuments.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 12
	|SELECT
	|	DocumentGoods.Ref         AS Ref,
	|	DocumentGoods.LineNumber    AS LineNumber,
	|	DocumentGoods.Products   AS Products,
	|	DocumentGoods.Products.DescriptionFull AS ItemName,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentGoods.Characteristic.DescriptionFull AS ItemVariantName,
	|	DocumentGoods.Series          AS Series,
	|	DocumentGoods.Products.KeepRecordsOfQualityCertificates AS KeepRecordsOfQualityCertificates,
	|	CASE
	|		WHEN DocumentGoods.Products.KeepRecordsOfQualityCertificates
	|			THEN
	|				CASE
	|					WHEN ProductsWithCertificates.QualityCertificate IS NULL
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE FALSE
	|	END                         AS NoValidCertificates,
	|	CASE
	|		WHEN DocumentGoods.Products.KeepRecordsOfQualityCertificates
	|			THEN ISNULL(ProductsWithCertificates.QualityCertificate, VALUE(Catalog.QualityCertificates.EmptyRef))
	|		ELSE VALUE(Catalog.QualityCertificates.EmptyRef)
	|	END                         AS QualityCertificate,
	|	ISNULL(ProductsWithCertificates.CertificateType, """") AS CertificateType,
	|	ISNULL(ProductsWithCertificates.CertificatePriority, 4) AS CertificatePriority,
	|	CASE
	|		WHEN DocumentGoods.Products.KeepRecordsOfQualityCertificates
	|			THEN
	|				CASE
	|					WHEN ProductsWithCertificates.QualityCertificate IS NULL
	|						THEN FALSE
	|					ELSE
	|						CASE
	|							WHEN ProductsWithCertificates.Expiration >= DocumentGoods.Date
	|									AND ProductsWithCertificates.StartOfValidityPeriod <= DocumentGoods.Date
	|								THEN TRUE
	|							ELSE FALSE
	|						END
	|				END
	|		ELSE FALSE
	|	END                         AS CertificateIsValid,
	|	ProductsWithCertificates.StatusOfRAC AS StatusOfRAC,
	|	ProductsWithCertificates.UpdateDateOfRACStatus AS UpdateDateOfRACStatus
	|FROM
	|	DocumentGoods AS DocumentGoods
	|		LEFT JOIN ProductsWithCertificates AS ProductsWithCertificates
	|		ON DocumentGoods.Products = ProductsWithCertificates.Products
	|			AND DocumentGoods.Characteristic = ProductsWithCertificates.Characteristic
	|			AND DocumentGoods.Series = ProductsWithCertificates.Series
	|			AND DocumentGoods.Date >= ProductsWithCertificates.StartOfValidityPeriod
	|			AND DocumentGoods.Date <= ProductsWithCertificates.Expiration
	|
	|ORDER BY
	|	Ref,
	|	LineNumber,
	|	Products,
	|	Characteristic,
	|	CertificateType DESC,
	|	Series,
	|	CertificateIsValid DESC,
	|	CertificatePriority
	|
	|TOTALS BY
	|	Ref,
	|	LineNumber,
	|	Products,
	|	Characteristic,
	|	CertificateType,
	|	Series
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 13
	|SELECT
	|	DocumentsData.Ref        AS Ref,
	|	ImplementationData.Number         AS Number,
	|	ImplementationData.Date          AS Date,
	|	UNDEFINED                   AS NumberOfDocumentBeingCorrected,
	|	UNDEFINED                   AS DateOfDocumentBeingCorrected,
	|	ImplementationData.Presentation AS Presentation
	|FROM
	|	DocumentsForWhichCertificatesAreRecorded AS DocumentsData
	|		INNER JOIN Document.CustomerInvoice AS ImplementationData
	|		ON DocumentsData.Ref = ImplementationData.Ref
	|WHERE
	|	DocumentsData.Ref REFS Document.CustomerInvoice
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsData.Ref           AS Ref,
	|	AdjustmentData.Number         AS Number,
	|	AdjustmentData.Date          AS Date,
	|	UNDEFINED                      AS NumberOfDocumentBeingCorrected,
	|	UNDEFINED                      AS DateOfDocumentBeingCorrected,
	|	AdjustmentData.Presentation AS Presentation
	|FROM
	|	DocumentsForWhichCertificatesAreRecorded AS DocumentsData
	|		INNER JOIN Document.SaleAdjustment AS AdjustmentData
	|		ON DocumentsData.Ref = AdjustmentData.Ref
	|WHERE
	|	DocumentsData.Ref REFS Document.SaleAdjustment
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsData.Ref           AS Ref,
	|	DataShipments.Number         AS Number,
	|	DataShipments.Date          AS Date,
	|	UNDEFINED                      AS NumberOfDocumentBeingCorrected,
	|	UNDEFINED                      AS DateOfDocumentBeingCorrected,
	|	DataShipments.Presentation AS Presentation
	|FROM
	|	DocumentsForWhichCertificatesAreRecorded AS DocumentsData
	|		INNER JOIN Document.GoodsShipmentToCustomer AS DataShipments
	|		ON DocumentsData.Ref = DataShipments.Ref
	|WHERE
	|	DocumentsData.Ref REFS Document.GoodsShipmentToCustomer
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsData.Ref         AS Ref,
	|	MovementData_.Number         AS Number,
	|	MovementData_.Date          AS Date,
	|	MovementData_.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
	|	MovementData_.CorrectedDocument.Date AS DateOfDocumentBeingCorrected,
	|	MovementData_.Presentation AS Presentation
	|FROM
	|	DocumentsForWhichCertificatesAreRecorded AS DocumentsData
	|		INNER JOIN Document.InventoryTransfer AS MovementData_
	|		ON DocumentsData.Ref = MovementData_.Ref
	|WHERE
	|	DocumentsData.Ref REFS Document.InventoryTransfer
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsData.Ref      AS Ref,
	|	TransmissionData.Number         AS Number,
	|	TransmissionData.Date          AS Date,
	|	UNDEFINED                 AS NumberOfDocumentBeingCorrected,
	|	UNDEFINED                 AS DateOfDocumentBeingCorrected,
	|	TransmissionData.Presentation AS Presentation
	|FROM
	|	DocumentsForWhichCertificatesAreRecorded AS DocumentsData
	|		INNER JOIN Document.TransferOfGoodsToBailee AS TransmissionData
	|		ON DocumentsData.Ref = TransmissionData.Ref
	|WHERE
	|	DocumentsData.Ref REFS Document.TransferOfGoodsToBailee
	|
	|ORDER BY
	|	Ref";
	
	Query.SetParameter("ObjectsArray", ArrayOfObjectsToRequest);
	
	ResultsArray = Query.ExecuteBatch();
	NumberOfResults = ResultsArray.Count();
	
	QueryResult = ResultsArray[NumberOfResults - 1]; // QueryResult
	PrintData = QueryResult.Select();
	
	QueryResult = ResultsArray[NumberOfResults - 2]; // QueryResult
	SelectionByDocuments = QueryResult.Select(QueryResultIteration.ByGroups);

	QueryResult = ResultsArray[NumberOfResults - 3]; // QueryResult
	ErrorSamplingBusinessOfOperation = QueryResult.Select();

	QueryResult = ResultsArray[NumberOfResults - 4]; // QueryResult
	SelectionBasedOnDocumentsWithoutCertificates_ = QueryResult.Select();
	
	Template = PrintManagement.PrintFormTemplate("Catalog.QualityCertificates.PF_MXL_CertificateRegistry");
	
	FirstDocument = True;
	
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	
	StatusVerificationParameters = New Structure;
	
	ProductsLocalization.AddParametersForCheckingComplianceOfStatusesOfNomenclatureCertificate(
		StatusVerificationParameters);
	
	While PrintData.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		Area = Template.GetArea("Header");
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, Area, PrintData.Ref);
		ParametersStructure = New Structure;
		ParametersStructure.Insert("TitleText",
			NStr("vi = 'Sổ đăng ký giấy chứng nhận mặt hàng';
				|ru = 'Реестр сертификатов номенклатуры';
				|en = 'Quality certificate registry'; fa = 'Quality certificate registry';
				|it = 'Il registro dei certificati di articolo';
				|pl = 'Rejestr certyfikatów towarowych';
				|tr = 'Öğe sertifikası sicili'", Common.DefaultLanguageCode()));
		Area.Parameters.Fill(ParametersStructure);
		
		SpreadsheetDocument.Put(Area);
		
		Area = Template.GetArea("Document");
		ParametersStructure = New Structure;
		ParametersStructure.Insert("PresentationOfDocument",
			TMCommonUseClientServer.GenerateDocumentTitle(PrintData));
		Area.Parameters.Fill(ParametersStructure);
		
		SpreadsheetDocument.Put(Area);
		
		// Creating arrays to check the output
		ArrayOfOutputAreas = New Array;
		
		TableHeaderArea = Template.GetArea("TableHeading");
		ParametersStructure = New Structure;
		ParametersStructure.Insert("PageNumber", "Page " + 1);
		TableHeaderArea.Parameters.Fill(ParametersStructure);
		SpreadsheetDocument.Put(TableHeaderArea);

		Area = Template.GetArea("TableHeader|BeginningOfTheLine");
		SpreadsheetDocument.Put(Area);
		Area = Template.GetArea("TableHeader|ProductColumn_");
		SpreadsheetDocument.Join(Area);
		Area = Template.GetArea("TableHeader|CertificateColumn");
		SpreadsheetDocument.Join(Area);
		
		PageNumber = 2;
		LineNumber = 1;
		AreaFirstRowProductColumn = Undefined;
		AreaFirstLineStartOfLine = Undefined;
		
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		SelectionByLineNumber = SelectionByDocuments.Select(QueryResultIteration.ByGroups);
		While SelectionByLineNumber.Next() Do
			
			OutputLinesForProductItems(
				SpreadsheetDocument,
				Template,
				AreaFirstRowProductColumn,
				PageNumber,
				LineNumber,
				ArrayOfOutputAreas);
			
			SelectionByProductType_ = SelectionByLineNumber.Select(QueryResultIteration.ByGroups);
			While SelectionByProductType_.Next() Do
				
				SelectionByCharacteristic = SelectionByProductType_.Select(QueryResultIteration.ByGroups);
				While SelectionByCharacteristic.Next() Do
					
					AreaFirstLineStartOfLine = Template.GetArea("TableRow|BeginningOfTheLine");
					ParametersStructure = New Structure;
					ParametersStructure.Insert("LineNumber",LineNumber);
					AreaFirstLineStartOfLine.Parameters.Fill(ParametersStructure);
					
					AreaFirstRowProductColumn = Template.GetArea("TableRow|ProductColumn_");
					AreaFirstRowProductColumn.Parameters.Fill(SelectionByCharacteristic);
					
					ProductPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
						SelectionByCharacteristic.ItemName,
						SelectionByCharacteristic.ItemVariantName,
						,
						,
						AdditionalParametersProductPresentation);
					
					ParametersStructure = New Structure;
					ParametersStructure.Insert("OwnGoods",ProductPresentation);
					AreaFirstRowProductColumn.Parameters.Fill(ParametersStructure);
					
					SelectionByCertificateType = SelectionByCharacteristic.Select(QueryResultIteration.ByGroups);
					While SelectionByCertificateType.Next() Do
						
						CertificatesArray = New Array;
						AbortSeriesSelection = False;
						SelectionBySeries = SelectionByCertificateType.Select(QueryResultIteration.ByGroups);
						
						While SelectionBySeries.Next() Do
							
							Selection = SelectionBySeries.Select();
							AbortSelection = False;
							ValidCertificateForSeriesAdded = False;
							While Selection.Next() Do
								
								NoteText2 = "";
								
								If Not Selection.KeepRecordsOfQualityCertificates Then
									
									ScopeOfApplication_9 = Template.GetArea(
										"RowOfCertificateTable|CertificateColumn");
									ParametersStructure = New Structure;
									ParametersStructure.Insert("Certificate",
										NStr("vi = '<Không quản lý giấy chứng nhận hàng hóa>';
											|ru = '<Учет сертификатов не ведется>';
											|en = '<Certificates are not recorded>'; fa = '<Certificates are not recorded>';
											|it = '<I certificati non vengono registrati>';
											|pl = '<ewidencja certyfikatów nie jest prowadzona>';
											|tr = '<Sertifikaların muhasebesi yapılmıyor>'", Common.DefaultLanguageCode()));
									ScopeOfApplication_9.Parameters.Fill(ParametersStructure);
									
									AbortSeriesSelection = True;
									AbortSelection = True;
									
								ElsIf Selection.NoValidCertificates Then
									
									ScopeOfApplication_9 = Template.GetArea(
										"TableRowCertificateBold|CertificateColumn");
									ParametersStructure = New Structure;
									ParametersStructure.Insert("Certificate",
										NStr("vi = '<Không có giấy chứng nhận còn hiệu lực>';
											|ru = '<Нет действующих сертификатов>';
											|en = '<No valid certificates>'; fa = '<No valid certificates>';
											|it = '<Non ci sono i certificati in vigore>';
											|pl = '<Brak ważnych certyfikatów>';
											|tr = '<Geçerli sertifika mevcut değil>'", Common.DefaultLanguageCode()));
									ScopeOfApplication_9.Parameters.Fill(ParametersStructure);
									
									Text = StringFunctionsClientServer.SubstituteParametersToString(
										NStr("vi = 'Đối với hàng hóa %1 không có giấy chứng nhận. Cần chỉ ra giấy chứng nhận hàng hóa.';
											|ru = 'Для товара %1 отсутствуют зарегистрированные сертификаты. Требуется указать сертификаты номенклатуры.';
											|en = 'There are no registered certificates for goods %1. It is required to specify the quality certificates.'; fa = 'There are no registered certificates for goods %1. It is required to specify the quality certificates.';
											|it = 'Per il prodotto %1 mancano i certificati registrati. Indicare i certificati di articolo.';
											|pl = 'Dla towaru %1 brak zarejestrowanych certyfikatów. Należy wskazać certyfikaty towaru.';
											|tr = '%1 ürünü için kayıtlı sertifika mevcut değil. Kalite belgelerini belirtmeniz gerekir.'"),
										ProductPresentation);
									Common.MessageToUser(
										Text,
										Selection.Products);
									
									AbortSeriesSelection = True;
									AbortSelection = True;
									
								ElsIf Not Selection.CertificateIsValid Then
									
									If ValidCertificateForSeriesAdded Then
										Break;
									EndIf;
									
									If ValueIsFilled(Selection.Series) Then
										ErrorText = NStr("vi = '<%CertificateType%: không có giấy chứng nhận còn hiệu lực đối với sê-ri %Series%>';
														|ru = '<%CertificateType%: нет действующих сертификатов для серии %Series%>';
														|en = '<%CertificateType%: no valid certificates for batch %Series%>'; fa = '<%CertificateType%: no valid certificates for batch %Series%>';
														|it = '<%CertificateType%: mancano i certificati in vigore per la serie %Series%>';
														|pl = '<%CertificateType%: brak ważnych certyfikatów dla serii %Series%>';
														|tr = '<%CertificateType%: parti için geçerli sertifikalar mevcut değil %Series%>'");
										
										PresentationOfProductsWithSeries = ProductsClientServer.ProductPresentation(
											SelectionByCharacteristic.ItemName,
											SelectionByCharacteristic.ItemVariantName,
											,
											Selection.Series);
										
										Text = StringFunctionsClientServer.SubstituteParametersToString(
											NStr("vi = 'Đối với hàng hóa %1 không có giấy chứng nhận có hiệu lực (%2). Cần ghi nhận giấy chứng nhận hàng hóa có hiệu lực.';
												|ru = 'Для товара %1 нет действующих сертификатов (%2). Требуется зарегистрировать действующий сертификат.';
												|en = 'There are no valid certificates (%2) for goods %1. It is required to register a valid certificate.'; fa = 'There are no valid certificates (%2) for goods %1. It is required to register a valid certificate.';
												|it = 'Per il prodotto %1 non ci sono i certificati in vigore (%2). Registrare il certificato in vigore.';
												|pl = 'Dla towaru %1 brak zarejestrowanych certyfikatów (%2). Należy zarejestrować ważny certyfikat.';
												|tr = '%1 öğesinin geçerli sertifikaları mevcut değil (%2). Geçerli bir sertifikanın kaydedilmesi gerekir.'"),
											PresentationOfProductsWithSeries,
											Selection.CertificateType);
									Else
										ErrorText = NStr("vi = '<%CertificateType%: không có giấy chứng nhận còn hiệu lực>';
														|ru = '<%CertificateType%: нет действующих сертификатов>';
														|en = '<%CertificateType%: no valid certificates>'; fa = '<%CertificateType%: no valid certificates>';
														|it = '<%CertificateType%: non ci sono i certificati in vigore>';
														|pl = '<%CertificateType%: brak ważnych certyfikatów>';
														|tr = '<%CertificateType%: geçerli sertifika mevcut değil>'");
										Text = StringFunctionsClientServer.SubstituteParametersToString(
											NStr("vi = 'Đối với hàng hóa %1 không có giấy chứng nhận có hiệu lực (%2). Cần ghi nhận giấy chứng nhận hàng hóa có hiệu lực.';
												|ru = 'Для товара %1 нет действующих сертификатов (%2). Требуется зарегистрировать действующий сертификат.';
												|en = 'There are no valid certificates (%2) for goods %1. It is required to register a valid certificate.'; fa = 'There are no valid certificates (%2) for goods %1. It is required to register a valid certificate.';
												|it = 'Per il prodotto %1 non ci sono i certificati in vigore (%2). Registrare il certificato in vigore.';
												|pl = 'Dla towaru %1 brak zarejestrowanych certyfikatów (%2). Należy zarejestrować ważny certyfikat.';
												|tr = '%1 öğesinin geçerli sertifikaları mevcut değil (%2). Geçerli bir sertifikanın kaydedilmesi gerekir.'"),
											ProductPresentation,
											Selection.CertificateType);
									EndIf;
									
									AbortSelection = True;
									ErrorText = StrReplace(ErrorText,"%CertificateType%",Selection.CertificateType);
									ErrorText = StrReplace(ErrorText,"%Series%",Selection.Series);
									ScopeOfApplication_9 = Template.GetArea(
										"TableRowCertificateBold|CertificateColumn");
									ParametersStructure = New Structure;
									ParametersStructure.Insert("Certificate",ErrorText);
									ScopeOfApplication_9.Parameters.Fill(ParametersStructure);
									
									Common.MessageToUser(
											Text,
											Selection.Products);
									
								Else
									
									If CertificatesArray.Find(Selection.QualityCertificate) <> Undefined Then
										Continue;
									EndIf;
									
									ProductsLocalization.CheckThatStatusOfItemCertificateMatches(
										Selection,
										NoteText2,
										StatusVerificationParameters);
									
									ScopeOfApplication_9 = Template.GetArea(
										"RowOfCertificateTable|CertificateColumn");
									ParametersStructure = New Structure;
									ParametersStructure.Insert("Certificate", Selection.QualityCertificate);
									ParametersStructure.Insert("QualityCertificate", Selection.QualityCertificate);
									ScopeOfApplication_9.Parameters.Fill(ParametersStructure);
									
									CertificatesArray.Add(Selection.QualityCertificate);
									ValidCertificateForSeriesAdded = True;
									
								EndIf;
								
								ArrayOfOutputAreas.Add(ScopeOfApplication_9);
								If Not IsBlankString(NoteText2) Then
									AreaNote = Template.GetArea(
										"TableRowNote|CertificateColumn");
									ParametersStructure = New Structure;
									ParametersStructure.Insert("Note", NoteText2);
									AreaNote.Parameters.Fill(ParametersStructure);
									ArrayOfOutputAreas.Add(AreaNote);
								EndIf;
								
								If AbortSelection Then
									Break;
								EndIf;
								
							EndDo;
							
							If AbortSeriesSelection Then
								Break;
							EndIf;
							
						EndDo;
					EndDo;
				EndDo;
			EndDo;
		EndDo;

		OutputLinesForProductItems(
			SpreadsheetDocument,
			Template,
			AreaFirstRowProductColumn,
			PageNumber,
			LineNumber,
			ArrayOfOutputAreas);
		
		Area = Template.GetArea("TableFooter|BeginningOfTheLine");
		SpreadsheetDocument.Put(Area);
		Area = Template.GetArea("TableFooter|ProductColumn_");
		SpreadsheetDocument.Join(Area);
		Area = Template.GetArea("TableFooter|CertificateColumn");
		SpreadsheetDocument.Join(Area);

		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
	EndDo;
	
	While SelectionBasedOnDocumentsWithoutCertificates_.Next() Do
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong chứng từ %1 không có hàng hóa cần quản lý giấy chứng nhận hàng hóa. Không cần in sổ đăng ký giấy chứng nhận hàng hóa.';
				|ru = 'В документе %1 отсутствуют товары, для которых ведется учет сертификатов. Печать реестра сертификатов номенклатуры не требуется.';
				|en = 'Goods for which certificate records are kept are missing in document %1. Printing of quality certificate registry is not required.'; fa = 'Goods for which certificate records are kept are missing in document %1. Printing of quality certificate registry is not required.';
				|it = 'Nel documento %1 mancano i prodotti, per i quali viene effettuata la registrazione dei certificati. Non è richiesta la stampa del registro dei certificati di articolo.';
				|pl = 'W dokumencie %1 brak towarów, dla których jest prowadzona ewidencja certyfikatów. Drukowanie rejestru certyfikatów towarów nie jest konieczne.';
				|tr = '%1 belgesinde sertifika muhasebesinin tutulduğu hiçbir öğe mevcut değil. Kalite belgesi için sicili yazdırma gerekli değildir.'"),
			String(SelectionBasedOnDocumentsWithoutCertificates_.Ref));
		Common.MessageToUser(
			Text,
			SelectionBasedOnDocumentsWithoutCertificates_.Ref);
	EndDo;
	
	ReportOnResultsOfVerificationOfOperationOfDocument(ErrorSamplingBusinessOfOperation);
	
	SpreadsheetDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

Procedure OutputLinesForProductItems(SpreadsheetDocument,Template,AreaFirstRowProductColumn,PageNumber,LineNumber,ArrayOfOutputAreas)
	
	If AreaFirstRowProductColumn <> Undefined Then
		
		FirstRow = True;
		OutputDelimiter = False;
		
		If Not SpreadsheetDocument.CheckPut(ArrayOfOutputAreas) Then	
			OutputDelimiter = True;				
		EndIf;
		
		If OutputDelimiter Then
			
			Area = Template.GetArea("TableFooter|BeginningOfTheLine");
			SpreadsheetDocument.Put(Area);
			Area = Template.GetArea("TableFooter|ProductColumn_");
			SpreadsheetDocument.Join(Area);
			Area = Template.GetArea("TableFooter|CertificateColumn");
			SpreadsheetDocument.Join(Area);
			
			SpreadsheetDocument.PutHorizontalPageBreak();
			
			TableHeaderArea = Template.GetArea("TableHeading");
			ParametersStructure = New Structure;
			ParametersStructure.Insert("PageNumber", "Page " + PageNumber);
			TableHeaderArea.Parameters.Fill(ParametersStructure);
			SpreadsheetDocument.Put(TableHeaderArea);
			PageNumber = PageNumber + 1;
			
			Area = Template.GetArea("TableHeader|BeginningOfTheLine");
			SpreadsheetDocument.Put(Area);
			Area = Template.GetArea("TableHeader|ProductColumn_");
			SpreadsheetDocument.Join(Area);
			Area = Template.GetArea("TableHeader|CertificateColumn");
			SpreadsheetDocument.Join(Area);
			
		EndIf;	
		
		For Each ScopeOfApplication_9 In ArrayOfOutputAreas Do
			
			If FirstRow Then
				
				AreaFirstLineStartOfLine = Template.GetArea("TableRow|BeginningOfTheLine");
				ParametersStructure = New Structure;
				ParametersStructure.Insert("LineNumber", LineNumber);
				AreaFirstLineStartOfLine.Parameters.Fill(ParametersStructure);
				
				SpreadsheetDocument.Put(AreaFirstLineStartOfLine);
				SpreadsheetDocument.Join(AreaFirstRowProductColumn);
				
				FirstRow = False;
			Else	
				Area = Template.GetArea("RowOfCertificateTable|BeginningOfTheLine");
				SpreadsheetDocument.Put(Area);
				
				Area = Template.GetArea("RowOfCertificateTable|ProductColumn_");
				SpreadsheetDocument.Join(Area);
			EndIf;	
			
			SpreadsheetDocument.Join(ScopeOfApplication_9);
		EndDo;	
		
		ArrayOfOutputAreas.Clear();
		LineNumber = LineNumber + 1;
	EndIf;
	
EndProcedure	

// Returns the generated tabular document of the printed Form "Certificates of nomenclature (images)".
//
// Parameters:
//	ObjectsArray - Array of DocumentRef - print objects.
//	PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects.
//
// Returns:
//	SpreadsheetDocument - the generated tabular document.
//
Function GeneratePrintedFormImagesOfCertificatesFromDocuments(ObjectsArray, PrintObjects) Export
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PARAMETERS_PRINTABLECertificatesProducts_ImagesOfCertificatesFromDocuments";
	
	If TypeOf(ObjectsArray[0]) = Type("DocumentRef.TransportationJob") Then	
		Query = New Query;
		Query.Text = TextOfRequestToGetListOfInvoicesFromTransportationTasks(); 		
		Query.SetParameter("TransportationJobs",ObjectsArray);
		ArrayOfObjectsToRequest = Query.Execute().Unload().UnloadColumn("ReferenceOrder");
	Else
		ArrayOfObjectsToRequest = ObjectsArray;
	EndIf;
	
	Query = New Query;
	Query.Text = TextOfRequestForCertificatesOfDocumentProductRange() + "
	|//////////////////////////////////////////////////////////////////////////////// 10
	|SELECT
	|	DocumentGoods.Ref      AS Ref,
	|	DocumentGoods.LineNumber AS LineNumber,
	|	CASE
	|		WHEN DocumentGoods.Products.KeepRecordsOfQualityCertificates
	|			THEN ISNULL(ProductsWithCertificates.QualityCertificate, VALUE(Catalog.QualityCertificates.EmptyRef))
	|		ELSE VALUE(Catalog.QualityCertificates.EmptyRef)
	|	END                      AS QualityCertificate,
	|	ISNULL(ProductsWithCertificates.CertificateType, """") AS CertificateType,
	|	CASE
	|		WHEN DocumentGoods.Products.KeepRecordsOfQualityCertificates
	|			THEN CASE
	|					WHEN ProductsWithCertificates.QualityCertificate IS NULL
	|						THEN FALSE
	|					ELSE CASE
	|							WHEN ProductsWithCertificates.Expiration >= DocumentGoods.Date
	|									AND ProductsWithCertificates.StartOfValidityPeriod <= DocumentGoods.Date
	|								THEN TRUE
	|							ELSE FALSE
	|						END
	|				END
	|		ELSE FALSE
	|	END                      AS CertificateIsValid,
	|	ISNULL(ProductsWithCertificates.CertificatePriority, 4) AS CertificatePriority
	|INTO QualityCertificates
	|FROM
	|	DocumentGoods AS DocumentGoods
	|		LEFT JOIN ProductsWithCertificates AS ProductsWithCertificates
	|		ON DocumentGoods.Products = ProductsWithCertificates.Products
	|			AND DocumentGoods.Characteristic = ProductsWithCertificates.Characteristic
	|			AND DocumentGoods.Series = ProductsWithCertificates.Series
	|WHERE
	|	CASE
	|			WHEN DocumentGoods.Products.KeepRecordsOfQualityCertificates
	|				THEN CASE
	|						WHEN ProductsWithCertificates.QualityCertificate IS NULL 
	|							THEN FALSE
	|						ELSE CASE
	|								WHEN ProductsWithCertificates.Expiration >= DocumentGoods.Date
	|									AND ProductsWithCertificates.StartOfValidityPeriod <= DocumentGoods.Date
	|									THEN TRUE
	|								ELSE FALSE
	|							END
	|					END
	|			ELSE FALSE
	|		END
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 11
	|SELECT
	|	QualityCertificatesAttachedFiles.Ref        AS Ref,
	|	QualityCertificatesAttachedFiles.FileOwner AS FileOwner
	|INTO QualityCertificatesAttachedFiles
	|FROM
	|	QualityCertificates AS QualityCertificates
	|		INNER JOIN Catalog.QualityCertificatesAttachedFiles AS QualityCertificatesAttachedFiles
	|		ON QualityCertificates.QualityCertificate = QualityCertificatesAttachedFiles.FileOwner
	|WHERE
	|	NOT QualityCertificatesAttachedFiles.DeletionMark
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 12
	|SELECT
	|	AllDocuments.Ref                               AS Ref,
	|	PRESENTATION(AllDocuments.Ref)                AS RepresentationOfTheReference,
	|	PRESENTATION(AllDocuments.BusinessOperation) AS PresentationOfBusinessTransaction
	|FROM
	|	AllDocuments AS AllDocuments
	|WHERE
	|	AllDocuments.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 13
	|SELECT
	|	DocumentsAccountingCertificates.Ref AS Ref,
	|	DocumentsAccountingCertificates.KeepRecordsOfQualityCertificates AS KeepRecordsOfQualityCertificates
	|FROM
	|	DocumentsAccountingCertificates AS DocumentsAccountingCertificates
	|WHERE
	|	NOT DocumentsAccountingCertificates.KeepRecordsOfQualityCertificates
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 14
	|SELECT DISTINCT
	|	QualityCertificates.Ref                    AS Ref,
	|	QualityCertificates.LineNumber               AS LineNumber,
	|	QualityCertificates.QualityCertificate    AS QualityCertificate,
	|	QualityCertificates.CertificateType            AS CertificateType,
	|	QualityCertificates.CertificateIsValid       AS CertificateIsValid,
	|	QualityCertificates.CertificatePriority      AS CertificatePriority,
	|	QualityCertificatesAttachedFiles.Ref AS AttachedFile,
	|	CASE
	|		WHEN QualityCertificatesAttachedFiles.Ref IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                             AS NoFiles
	|FROM
	|	QualityCertificates AS QualityCertificates
	|		LEFT JOIN QualityCertificatesAttachedFiles AS QualityCertificatesAttachedFiles
	|		ON QualityCertificates.QualityCertificate = QualityCertificatesAttachedFiles.FileOwner
	|
	|ORDER BY
	|	QualityCertificates.Ref,
	|	QualityCertificates.LineNumber,
	|	QualityCertificates.CertificateType DESC,
	|	QualityCertificates.CertificateIsValid DESC,
	|	QualityCertificates.CertificatePriority
	|
	|TOTALS BY
	|	Ref,
	|	LineNumber,
	|	CertificateType,
	|	QualityCertificate,
	|	CertificatePriority
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 15
	|SELECT DISTINCT
	|	ProductsWithCertificates.Products                      AS Products,
	|	ProductsWithCertificates.Products.DescriptionFull   AS ItemName,
	|	ProductsWithCertificates.Characteristic                    AS Characteristic,
	|	ProductsWithCertificates.Characteristic.DescriptionFull AS ItemVariantName,
	|	ProductsWithCertificates.Series                             AS Series,
	|	ProductsWithCertificates.CertificateType                    AS CertificateType
	|FROM
	|	ProductsWithCertificates AS ProductsWithCertificates
	|		LEFT JOIN QualityCertificates AS QualityCertificates
	|		ON ProductsWithCertificates.QualityCertificate = QualityCertificates.QualityCertificate
	|WHERE
	|	QualityCertificates.QualityCertificate IS NULL";
	
	Query.SetParameter("ObjectsArray", ArrayOfObjectsToRequest);
	
	ResultsArray = Query.ExecuteBatch();
	NumberOfResults = ResultsArray.Count();

	QueryResult = ResultsArray[NumberOfResults - 4]; // QueryResult
	ErrorSamplingBusinessOfOperation = QueryResult.Select();
	
	QueryResult = ResultsArray[NumberOfResults - 2]; // QueryResult
	SelectionByDocuments = QueryResult.Select(QueryResultIteration.ByGroups);
		
	QueryResult = ResultsArray[NumberOfResults - 3]; // QueryResult
	SelectionBasedOnDocumentsWithoutCertificates_ = QueryResult.Select();
	
	QueryResult = ResultsArray[NumberOfResults - 1]; // QueryResult
	SamplingForProductsWithoutValidCertificates = QueryResult.Select();
	
	Template = PrintManagement.PrintFormTemplate("Catalog.QualityCertificates.PF_MXL_CertificateImages");
			
	FirstDocument = True;
	
	While SelectionByDocuments.Next() Do

		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
					
		SelectionByLineNumber = SelectionByDocuments.Select(QueryResultIteration.ByGroups);
		While SelectionByLineNumber.Next() Do
			
			SelectionByCertificateType = SelectionByLineNumber.Select(QueryResultIteration.ByGroups);
			While SelectionByCertificateType.Next() Do
				
				CertificateSelection_ = SelectionByCertificateType.Select(QueryResultIteration.ByGroups);
				While CertificateSelection_.Next() Do
					
					PrioritySelection_ = CertificateSelection_.Select(QueryResultIteration.ByGroups);
					While PrioritySelection_.Next() Do
						
						Selection = PrioritySelection_.Select();
						While Selection.Next() Do
							
							If Selection.NoFiles Then
								Text = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("vi = 'Trong chứng nhận hàng hóa %1 không có hình ảnh đính kèm. Cần đính kèm tệp hình ảnh.';
									|ru = 'В сертификате номенклатуры %1 отсутствуют присоединенные изображения. Требуется прикрепить файл изображения.';
									|en = 'There is no attached image in quality certificate %1. Attach the image file.'; fa = 'There is no attached image in quality certificate %1. Attach the image file.';
									|it = 'Nel certificato di articolo %1 mancano le immagini allegati. È necessario allegare il file dell''immagine.';
									|pl = 'W certyfikacie towaru %1 brak dołączonych obrazów. Należy dołączyć plik obrazu.';
									|tr = '%1 kalite belgesinde ekli resim mevcut değil. Bir resim dosyası eklenmesi gerekiyor.'"),
								String(Selection.QualityCertificate));
								Common.MessageToUser(
								Text,
								Selection.QualityCertificate);
								Break;

							EndIf;	
								
							SpreadsheetDocument.PutHorizontalPageBreak();
							
							Area = Template.GetArea("Image");		 
							Drawing = Area.Drawings.Add(SpreadsheetDocumentDrawingType.Picture); 
							Drawing.Height = 297;
							Drawing.Width = 210;
							
							Drawing.TopBorder = False;
							Drawing.BottomBorder = False;
							Drawing.LeftBorder = False;
							Drawing.RightBorder = False;
							
							Drawing.PictureSize = PictureSize.AutoSize;
							Drawing.Picture = New Picture(FilesOperations.FileBinaryData(Selection.AttachedFile));
							Drawing.Line = New Line(SpreadsheetDocumentDrawingLineType.None);
							SpreadsheetDocument.Put(Area);
							
						EndDo;	
						
						Break;
						
					EndDo;		
				EndDo;
			EndDo;
		EndDo;
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, SelectionByDocuments.Ref);
		
	EndDo;
	
	While SelectionBasedOnDocumentsWithoutCertificates_.Next() Do
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong chứng từ %1 không có hàng hóa cần quản lý giấy chứng nhận hàng hóa. Không cần in hình ảnh giấy chứng nhận hàng hóa.';
				|ru = 'В документе %1 отсутствуют товары, для которых ведется учет сертификатов. Печать изображений сертификатов номенклатуры не требуется.';
				|en = 'Goods for which certificate records are kept are missing in document %1. Printing of quality certificate images is not required.'; fa = 'Goods for which certificate records are kept are missing in document %1. Printing of quality certificate images is not required.';
				|it = 'Nel documento %1 mancano i prodotti, per i quali viene effettuata la registrazione dei certificati. Non è richiesta la stampa delle immagini dei certificati di articolo.';
				|pl = 'W dokumencie %1 brak towarów, dla których jest prowadzona ewidencja certyfikatów. Drukowanie obrazów certyfikatów towarów nie jest konieczne.';
				|tr = '%1 belgesinde sertifika muhasebesinin tutulduğu hiç bir öğe mevcut değil. Kalite belgesi resimlerinin yazdırılmasına gerek yoktur.'"),
			String(SelectionBasedOnDocumentsWithoutCertificates_.Ref));
		Common.MessageToUser(
			Text,
			SelectionBasedOnDocumentsWithoutCertificates_.Ref);
	EndDo;
	
	If SamplingForProductsWithoutValidCertificates.Count() > 0 Then
		
		GoodsWithoutValidCertificates = New Map;
		VerifiableItems          = New Array;
		VerifiableCharacteristics        = New Array;
		TestableSeries                 = New Array;
		ProductData_8                     = GoodsDataWithNonValidCertificatesForPrinting();
		
		While SamplingForProductsWithoutValidCertificates.Next() Do
			
			VerifiableItems.Add(SamplingForProductsWithoutValidCertificates.Products);
			VerifiableCharacteristics.Add(SamplingForProductsWithoutValidCertificates.Characteristic);
			TestableSeries.Add(SamplingForProductsWithoutValidCertificates.Series);
			
			FillPropertyValues(ProductData_8, SamplingForProductsWithoutValidCertificates);
			ProductKey = GoodsKeyByCertificateValidityMeasurements(
							SamplingForProductsWithoutValidCertificates.Products,
							SamplingForProductsWithoutValidCertificates.Characteristic,
							SamplingForProductsWithoutValidCertificates.Series);
			GoodsWithoutValidCertificates.Insert(ProductKey, ProductData_8);
			
		EndDo;
		
		Query = New Query;
		Query.Text =
		"SELECT DISTINCT
		|	REFPRESENTATION(CertificateScopes.Products)   AS ProductPresentation,
		|	REFPRESENTATION(CertificateScopes.Characteristic) AS CharacteristicPresentation,
		|	REFPRESENTATION(CertificateScopes.Series)          AS BatchPresentation
		|FROM
		|	InformationRegister.QualityCertificateApplicationAreas AS CertificateScopes
		|		INNER JOIN Catalog.QualityCertificates AS QualityCertificates
		|		ON CertificateScopes.QualityCertificate = QualityCertificates.Ref
		|WHERE
		|	NOT QualityCertificates.DeletionMark
		|	AND QualityCertificates.Status = VALUE(Enum.StatusesOfQualityCertificates.Valid_)
		|	AND CertificateScopes.Products IN (&VerifiableItems)
		|	AND CertificateScopes.Characteristic IN (&VerifiableCharacteristics)
		|	AND CertificateScopes.Series IN (&TestableSeries)";
		
		Query.SetParameter("VerifiableItems",   VerifiableItems);
		Query.SetParameter("VerifiableCharacteristics", VerifiableCharacteristics);
		Query.SetParameter("TestableSeries",          TestableSeries);
		
		SelectionOfValidGoodsCertificates = Query.Execute().Select();
		
		ArrayOfGoodsKeysWithValidCertificates = New Array();
		While SelectionOfValidGoodsCertificates.Next() Do
			ArrayOfGoodsKeysWithValidCertificates.Add(
				SelectionOfValidGoodsCertificates.ProductPresentation
				+ SelectionOfValidGoodsCertificates.CharacteristicPresentation
				+ SelectionOfValidGoodsCertificates.BatchPresentation);
		EndDo;
		
		// Removing items from the collection that have valid item certificates.
		For Each GoodsKeyWithValidCertificates In ArrayOfGoodsKeysWithValidCertificates Do
			GoodsWithoutValidCertificates.Delete(GoodsKeyWithValidCertificates);
		EndDo;
		
		If GoodsWithoutValidCertificates.Count() > 0 Then
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
		EndIf;
		
		For Each KeyAndValue In GoodsWithoutValidCertificates Do
			
			ProductData_8 = KeyAndValue.Value;
			
			GoodsPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
				ProductData_8.ItemName,
				ProductData_8.ItemVariantName,
				,
				ProductData_8.Series,
				AdditionalParametersProductPresentation);
			
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đối với hàng hóa %1 không có giấy chứng nhận có hiệu lực (%2). Cần ghi nhận giấy chứng nhận hàng hóa có hiệu lực.';
					|ru = 'Для товара %1 нет действующих сертификатов (%2). Требуется зарегистрировать действующий сертификат.';
					|en = 'There are no valid certificates (%2) for goods %1. It is required to register a valid certificate.'; fa = 'There are no valid certificates (%2) for goods %1. It is required to register a valid certificate.';
					|it = 'Per il prodotto %1 non ci sono i certificati in vigore (%2). Registrare il certificato in vigore.';
					|pl = 'Dla towaru %1 brak zarejestrowanych certyfikatów (%2). Należy zarejestrować ważny certyfikat.';
					|tr = '%1 öğesinin geçerli sertifikaları mevcut değil (%2). Geçerli bir sertifikanın kaydedilmesi gerekir.'"),
				GoodsPresentation,
				ProductData_8.CertificateType);
			Common.MessageToUser(
				Text,
				ProductData_8.Products);
			
		EndDo;
		
	EndIf;
	
	ReportOnResultsOfVerificationOfOperationOfDocument(ErrorSamplingBusinessOfOperation);
	
	SpreadsheetDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

// Returns the generated tabular document of the printed Form "Certificate Images".
//
// Parameters:
//	ObjectsArray - Array of DocumentRef - print objects.
//	PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects.
//
// Returns:
//	SpreadsheetDocument - the generated tabular document.
//
Function ToFormPrintedFormOfImageOfCertificates(ObjectsArray, PrintObjects) Export
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PARAMETERS_PRINTINGSCertificatesProducts_ImagesOfCertificates";
	
	Query = New Query;
	Query.Text = 
	
	"SELECT DISTINCT
	|	QualityCertificates.Ref		AS Ref,
	|	QualityCertificates.IsFolder	AS IsFolder
	|INTO QualityCertificates
	|FROM
	|	Catalog.QualityCertificates AS QualityCertificates
	|WHERE
	|	QualityCertificates.Ref IN (&ObjectsArray)
	|	OR QualityCertificates.Parent IN (&ObjectsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	QualityCertificatesAttachedFiles.Ref,
	|	QualityCertificatesAttachedFiles.FileOwner
	|INTO QualityCertificatesAttachedFiles
	|FROM
	|	Catalog.QualityCertificatesAttachedFiles AS QualityCertificatesAttachedFiles
	|		INNER JOIN QualityCertificates AS QualityCertificates
	|		ON QualityCertificatesAttachedFiles.FileOwner = QualityCertificates.Ref
	|WHERE
	|	QualityCertificates.IsFolder = FALSE
	|	AND QualityCertificatesAttachedFiles.DeletionMark = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	QualityCertificates.Ref,
	|	ISNULL(QualityCertificatesAttachedFiles.Ref, VALUE(Catalog.QualityCertificatesAttachedFiles.EmptyRef)) AS AttachedFile,
	|	CASE
	|		WHEN QualityCertificatesAttachedFiles.Ref IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS NoFiles
	|INTO ProductCertificatesWithAttachedFiles
	|FROM
	|	QualityCertificates AS QualityCertificates
	|		LEFT JOIN QualityCertificatesAttachedFiles AS QualityCertificatesAttachedFiles
	|		ON (QualityCertificatesAttachedFiles.FileOwner = QualityCertificates.Ref)
	|WHERE
	|	QualityCertificates.IsFolder = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductCertificatesWithAttachedFiles.Ref AS Ref,
	|	ProductCertificatesWithAttachedFiles.AttachedFile
	|FROM
	|	ProductCertificatesWithAttachedFiles AS ProductCertificatesWithAttachedFiles
	|WHERE
	|	ProductCertificatesWithAttachedFiles.NoFiles = FALSE
	|
	|ORDER BY
	|	Ref
	|AUTOORDER
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductCertificatesWithAttachedFiles.Ref AS Ref,
	|	ProductCertificatesWithAttachedFiles.AttachedFile
	|FROM
	|	ProductCertificatesWithAttachedFiles AS ProductCertificatesWithAttachedFiles
	|WHERE
	|	ProductCertificatesWithAttachedFiles.NoFiles = TRUE
	|
	|ORDER BY
	|	Ref
	|AUTOORDER
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	QualityCertificates.Ref AS Ref
	|FROM
	|	QualityCertificates AS QualityCertificates
	|WHERE
	|	QualityCertificates.IsFolder = TRUE
	|
	|ORDER BY
	|	Ref
	|AUTOORDER";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
		
	ResultsArray = Query.ExecuteBatch();
	
	QueryResult = ResultsArray[3]; // QueryResult
	Selection = QueryResult.Select();
	
	QueryResult = ResultsArray[4]; // QueryResult
	SelectionBasedOnDocumentsWithoutCertificates = QueryResult.Select();
	
	QueryResult = ResultsArray[5]; // QueryResult
	GroupSelection_ = QueryResult.Select();
	
	Template = PrintManagement.PrintFormTemplate("Catalog.QualityCertificates.PF_MXL_CertificateImages");
	
	While Selection.Next() Do
		
		SpreadsheetDocument.PutHorizontalPageBreak();
		
		Area = Template.GetArea("Image");
		
		Drawing = Area.Drawings.Add(SpreadsheetDocumentDrawingType.Picture); 
		Drawing.Height = 297;
		Drawing.Width = 210;
		
		Drawing.TopBorder = False;
		Drawing.BottomBorder = False;
		Drawing.LeftBorder = False;
		Drawing.RightBorder = False;
		
		Drawing.PictureSize = PictureSize.AutoSize;
		Drawing.Picture = New Picture(FilesOperations.FileBinaryData(Selection.AttachedFile));
		Drawing.Line = New Line(SpreadsheetDocumentDrawingLineType.None);
		SpreadsheetDocument.Put(Area);
		
	EndDo;
	
	While SelectionBasedOnDocumentsWithoutCertificates.Next() Do
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong chứng nhận hàng hóa %1 không có hình ảnh đính kèm. Cần đính kèm tệp hình ảnh.';
				|ru = 'В сертификате номенклатуры %1 отсутствуют присоединенные изображения. Требуется прикрепить файл изображения.';
				|en = 'There is no attached image in quality certificate %1. Attach the image file.'; fa = 'There is no attached image in quality certificate %1. Attach the image file.';
				|it = 'Nel certificato di articolo %1 mancano le immagini allegati. È necessario allegare il file dell''immagine.';
				|pl = 'W certyfikacie towaru %1 brak dołączonych obrazów. Należy dołączyć plik obrazu.';
				|tr = '%1 kalite belgesinde ekli resim mevcut değil. Bir resim dosyası eklenmesi gerekiyor.'"),
			String(SelectionBasedOnDocumentsWithoutCertificates.Ref));
		Common.MessageToUser(
			Text,
			SelectionBasedOnDocumentsWithoutCertificates.Ref);
	EndDo;
	
	While GroupSelection_.Next() Do
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đối với nhóm ""%1"" không cần tiến hành ghi nhận hình ảnh của chứng nhận.';
				|ru = 'Для группы ""%1"" не требуется ведение учета изображений сертификатов.';
				|en = 'There is no need to keep records of certificate images for the %1 group.'; fa = 'There is no need to keep records of certificate images for the %1 group.';
				|it = 'There is no need to keep records of certificate images for the %1 group.';
				|pl = 'There is no need to keep records of certificate images for the %1 group.';
				|tr = '""%1"" grubu için sertifika resimlerinin muhasebesini tutmak gerekli değildir.'"),
			String(GroupSelection_.Ref));
		Common.MessageToUser(
			Text,
			GroupSelection_.Ref);
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

// Returns the generated tabular document of the printed Form "Certificates of nomenclature (images without duplicates)".
//
// Parameters:
//	ObjectsArray - Array of DocumentRef - print objects.
//	PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects.
//
// Returns:
//	SpreadsheetDocument - the generated tabular document.
//
Function GeneratePrintedFormImagesOfCertificatesFromDocumentsWithoutDuplicates(ObjectsArray, PrintObjects) Export
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PARAMETERS_PRINTINGSCertificatesProducts_ImagesOfCertificatesFromDocumentsWithoutDuplicates";
	
	If TypeOf(ObjectsArray[0]) = Type("DocumentRef.TransportationJob") Then	
		Query = New Query;
		Query.Text = TextOfRequestToGetListOfInvoicesFromTransportationTasks(); 		
		Query.SetParameter("TransportationJobs",ObjectsArray);
		ArrayOfObjectsToRequest = Query.Execute().Unload().UnloadColumn("ReferenceOrder");
	Else
		ArrayOfObjectsToRequest = ObjectsArray;
	EndIf;
	
	Query = New Query;
	Query.Text = TextOfRequestForCertificatesOfDocumentProductRange() + "
	|//////////////////////////////////////////////////////////////////////////////// 10
	|SELECT
	|	CASE
	|		WHEN DocumentGoods.Ref REFS Document.InventoryTransfer
	|			THEN DocumentGoods.Ref.DestinationWarehouse
	|		ELSE DocumentGoods.Ref.Counterparty
	|	END                                               AS GroupingCertificates,
	|	CASE
	|		WHEN DocumentGoods.Products.KeepRecordsOfQualityCertificates
	|			THEN ISNULL(ProductsWithCertificates.QualityCertificate, VALUE(Catalog.QualityCertificates.EmptyRef))
	|		ELSE VALUE(Catalog.QualityCertificates.EmptyRef)
	|	END                                               AS QualityCertificate,
	|	ISNULL(ProductsWithCertificates.CertificateType, """") AS CertificateType,
	|	CASE
	|		WHEN DocumentGoods.Products.KeepRecordsOfQualityCertificates
	|			THEN CASE
	|					WHEN ProductsWithCertificates.QualityCertificate IS NULL
	|						THEN FALSE
	|					ELSE CASE
	|							WHEN ProductsWithCertificates.Expiration >= DocumentGoods.Date
	|									AND ProductsWithCertificates.StartOfValidityPeriod <= DocumentGoods.Date
	|								THEN TRUE
	|							ELSE FALSE
	|						END
	|				END
	|		ELSE FALSE
	|	END                                               AS CertificateIsValid,
	|	ProductsWithCertificates.CertificatePriority           AS CertificatePriority
	|INTO QualityCertificates
	|FROM
	|	DocumentGoods AS DocumentGoods
	|		LEFT JOIN ProductsWithCertificates AS ProductsWithCertificates
	|		ON DocumentGoods.Products = ProductsWithCertificates.Products
	|			AND DocumentGoods.Characteristic = ProductsWithCertificates.Characteristic
	|			AND DocumentGoods.Series = ProductsWithCertificates.Series
	|WHERE
	|	CASE
	|		WHEN DocumentGoods.Products.KeepRecordsOfQualityCertificates
	|			THEN CASE
	|					WHEN ProductsWithCertificates.QualityCertificate IS NULL 
	|						THEN FALSE
	|					ELSE CASE
	|							WHEN ProductsWithCertificates.Expiration >= DocumentGoods.Date
	|									AND ProductsWithCertificates.StartOfValidityPeriod <= DocumentGoods.Date
	|								THEN TRUE
	|							ELSE FALSE
	|						END
	|				END
	|		ELSE FALSE
	|	END
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 11
	|SELECT
	|	QualityCertificatesAttachedFiles.Ref        AS Ref,
	|	QualityCertificatesAttachedFiles.FileOwner AS FileOwner
	|INTO QualityCertificatesAttachedFiles
	|FROM
	|	QualityCertificates AS QualityCertificates
	|		INNER JOIN Catalog.QualityCertificatesAttachedFiles AS QualityCertificatesAttachedFiles
	|		ON QualityCertificates.QualityCertificate = QualityCertificatesAttachedFiles.FileOwner
	|WHERE
	|	NOT QualityCertificatesAttachedFiles.DeletionMark
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 12
	|SELECT
	|	AllDocuments.Ref                               AS Ref,
	|	PRESENTATION(AllDocuments.Ref)                AS RepresentationOfTheReference,
	|	PRESENTATION(AllDocuments.BusinessOperation) AS PresentationOfBusinessTransaction
	|FROM
	|	AllDocuments AS AllDocuments
	|WHERE
	|	AllDocuments.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 13
	|SELECT
	|	DocumentsAccountingCertificates.Ref AS Ref,
	|	DocumentsAccountingCertificates.KeepRecordsOfQualityCertificates AS KeepRecordsOfQualityCertificates
	|FROM
	|	DocumentsAccountingCertificates AS DocumentsAccountingCertificates
	|WHERE
	|	NOT DocumentsAccountingCertificates.KeepRecordsOfQualityCertificates
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 14
	|SELECT DISTINCT
	|	QualityCertificates.GroupingCertificates   AS Ref,
	|	QualityCertificates.QualityCertificate    AS QualityCertificate,
	|	QualityCertificates.CertificateType            AS CertificateType,
	|	QualityCertificates.CertificateIsValid       AS CertificateIsValid,
	|	QualityCertificates.CertificatePriority      AS CertificatePriority,
	|	QualityCertificatesAttachedFiles.Ref AS AttachedFile,
	|	CASE
	|		WHEN QualityCertificatesAttachedFiles.Ref IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS NoFiles
	|FROM
	|	QualityCertificates AS QualityCertificates
	|		LEFT JOIN QualityCertificatesAttachedFiles AS QualityCertificatesAttachedFiles
	|		ON QualityCertificates.QualityCertificate = QualityCertificatesAttachedFiles.FileOwner
	|
	|ORDER BY
	|	Ref,
	|	QualityCertificates.CertificateType DESC,
	|	QualityCertificates.CertificateIsValid DESC,
	|	QualityCertificates.CertificatePriority
	|
	|TOTALS BY
	|	GroupingCertificates,
	|	CertificateType,
	|	QualityCertificate,
	|	CertificatePriority
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 15
	|SELECT DISTINCT
	|	ProductsWithCertificates.Products                      AS Products,
	|	ProductsWithCertificates.Products.DescriptionFull   AS ItemName,
	|	ProductsWithCertificates.Characteristic                    AS Characteristic,
	|	ProductsWithCertificates.Characteristic.DescriptionFull AS ItemVariantName,
	|	ProductsWithCertificates.Series                             AS Series,
	|	ProductsWithCertificates.CertificateType                    AS CertificateType
	|FROM
	|	ProductsWithCertificates AS ProductsWithCertificates
	|		LEFT JOIN QualityCertificates AS QualityCertificates
	|		ON ProductsWithCertificates.QualityCertificate = QualityCertificates.QualityCertificate
	|WHERE
	|	QualityCertificates.QualityCertificate IS NULL";
	
	Query.SetParameter("ObjectsArray", ArrayOfObjectsToRequest);
	
	ResultsArray = Query.ExecuteBatch();
	NumberOfResults = ResultsArray.Count();

	QueryResult = ResultsArray[NumberOfResults - 4]; // QueryResult
	ErrorSamplingBusinessOfOperation = QueryResult.Select(QueryResultIteration.ByGroups);
	
	QueryResult = ResultsArray[NumberOfResults - 2]; // QueryResult
	SelectionByDimension = QueryResult.Select(QueryResultIteration.ByGroups);

	QueryResult = ResultsArray[NumberOfResults - 3]; // QueryResult
	SelectionBasedOnDocumentsWithoutCertificates_ = QueryResult.Select();

	QueryResult = ResultsArray[NumberOfResults - 1]; // QueryResult
	SamplingForProductsWithoutValidCertificates = QueryResult.Select();
	
	Template = PrintManagement.PrintFormTemplate("Catalog.QualityCertificates.PF_MXL_CertificateImages");
	
	FirstDocument = True;
	
	While SelectionByDimension.Next() Do

		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
					
		SelectionByCertificateType = SelectionByDimension.Select(QueryResultIteration.ByGroups);
		While SelectionByCertificateType.Next() Do
							
				CertificateSelection_ = SelectionByCertificateType.Select(QueryResultIteration.ByGroups);
				While CertificateSelection_.Next() Do
					
					PrioritySelection_ = CertificateSelection_.Select(QueryResultIteration.ByGroups);
					While PrioritySelection_.Next() Do
						
						Selection = PrioritySelection_.Select();
						While Selection.Next() Do
							
							If Selection.NoFiles Then
								Text = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("vi = 'Trong chứng nhận hàng hóa %1 không có hình ảnh đính kèm. Cần đính kèm tệp hình ảnh.';
									|ru = 'В сертификате номенклатуры %1 отсутствуют присоединенные изображения. Требуется прикрепить файл изображения.';
									|en = 'There is no attached image in quality certificate %1. Attach the image file.'; fa = 'There is no attached image in quality certificate %1. Attach the image file.';
									|it = 'Nel certificato di articolo %1 mancano le immagini allegati. È necessario allegare il file dell''immagine.';
									|pl = 'W certyfikacie towaru %1 brak dołączonych obrazów. Należy dołączyć plik obrazu.';
									|tr = '%1 kalite belgesinde ekli resim mevcut değil. Bir resim dosyası eklenmesi gerekiyor.'"),
								String(Selection.QualityCertificate));
								Common.MessageToUser(
								Text,
								Selection.QualityCertificate);
								Break;

							EndIf;	
								
							SpreadsheetDocument.PutHorizontalPageBreak();
							
							Area = Template.GetArea("Image");		 
							Drawing = Area.Drawings.Add(SpreadsheetDocumentDrawingType.Picture); 
							Drawing.Height = 297;
							Drawing.Width = 210;
							
							Drawing.TopBorder = False;
							Drawing.BottomBorder = False;
							Drawing.LeftBorder = False;
							Drawing.RightBorder = False;
							
							Drawing.PictureSize = PictureSize.AutoSize;
							Drawing.Picture = New Picture(FilesOperations.FileBinaryData(Selection.AttachedFile));
							Drawing.Line = New Line(SpreadsheetDocumentDrawingLineType.None);
							SpreadsheetDocument.Put(Area);
							
						EndDo;	
						
						Break;
						
					EndDo;		
				EndDo;
		EndDo;
		
		If ArrayOfObjectsToRequest.Count() = 1 Then 
			PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, ArrayOfObjectsToRequest[0]);
		Else	
			PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, SelectionByDimension.Ref);
		EndIf;
		
	EndDo;
	
	While SelectionBasedOnDocumentsWithoutCertificates_.Next() Do
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong chứng từ %1 không có hàng hóa cần quản lý chứng nhận hàng hóa.
			|Không cần in hình ảnh chứng nhận hàng hóa.';
			|ru = 'В документе %1 отсутствуют товары для которых ведется учет сертификатов.
			| Печать изображений сертификатов номенклатуры не требуется.';
			|en = 'Goods for which certificate records are kept are missing in document %1.
			|Printing of quality certificate images is not required.'; fa = 'Goods for which certificate records are kept are missing in document %1.
			|Printing of quality certificate images is not required.';
			|it = 'Nel documento %1 mancano i prodotti per i quali viene effettuata la registrazione dei certificati. 
			| La stampa delle immagini dei certificati di articolo non è richiesta.';
			|pl = 'W dokumencie %1 brak towarów, dla których jest prowadzona ewidencja certyfikatów.
			|Drukowanie obrazów certyfikatów towarów nie jest konieczne.';
			|tr = '%1 belgesinde sertifika muhasebesinin tutulduğu hiç bir öğe mevcut değil.
			| Kalite belgesi resimlerinin yazdırılmasına gerek yoktur.'"),
			String(SelectionBasedOnDocumentsWithoutCertificates_.Ref));
		Common.MessageToUser(
			Text,
			SelectionBasedOnDocumentsWithoutCertificates_.Ref);
	EndDo;
	
	If SamplingForProductsWithoutValidCertificates.Count() > 0 Then
		
		GoodsWithoutValidCertificates = New Map;
		VerifiableItems          = New Array;
		VerifiableCharacteristics        = New Array;
		TestableSeries                 = New Array;
		ProductData_8                     = GoodsDataWithNonValidCertificatesForPrinting();
		
		While SamplingForProductsWithoutValidCertificates.Next() Do
			
			VerifiableItems.Add(SamplingForProductsWithoutValidCertificates.Products);
			VerifiableCharacteristics.Add(SamplingForProductsWithoutValidCertificates.Characteristic);
			TestableSeries.Add(SamplingForProductsWithoutValidCertificates.Series);
			
			FillPropertyValues(ProductData_8, SamplingForProductsWithoutValidCertificates);
			ProductKey = GoodsKeyByCertificateValidityMeasurements(
							SamplingForProductsWithoutValidCertificates.Products,
							SamplingForProductsWithoutValidCertificates.Characteristic,
							SamplingForProductsWithoutValidCertificates.Series);
			GoodsWithoutValidCertificates.Insert(ProductKey, ProductData_8);
			
		EndDo;
		
		Query = New Query;
		Query.Text =
		"SELECT DISTINCT
		|	REFPRESENTATION(CertificateScopes.Products)   AS ProductPresentation,
		|	REFPRESENTATION(CertificateScopes.Characteristic) AS CharacteristicPresentation,
		|	REFPRESENTATION(CertificateScopes.Series)          AS BatchPresentation
		|FROM
		|	InformationRegister.QualityCertificateApplicationAreas AS CertificateScopes
		|		INNER JOIN Catalog.QualityCertificates AS QualityCertificates
		|		ON CertificateScopes.QualityCertificate = QualityCertificates.Ref
		|WHERE
		|	NOT QualityCertificates.DeletionMark
		|	AND QualityCertificates.Status = VALUE(Enum.StatusesOfQualityCertificates.Valid_)
		|	AND CertificateScopes.Products IN (&VerifiableItems)
		|	AND CertificateScopes.Characteristic IN (&VerifiableCharacteristics)
		|	AND CertificateScopes.Series IN (&TestableSeries)";
		
		Query.SetParameter("VerifiableItems",   VerifiableItems);
		Query.SetParameter("VerifiableCharacteristics", VerifiableCharacteristics);
		Query.SetParameter("TestableSeries",          TestableSeries);
		
		SelectionOfValidGoodsCertificates = Query.Execute().Select();
		
		ArrayOfGoodsKeysWithValidCertificates = New Array();
		While SelectionOfValidGoodsCertificates.Next() Do
			ArrayOfGoodsKeysWithValidCertificates.Add(
				SelectionOfValidGoodsCertificates.ProductPresentation
				+ SelectionOfValidGoodsCertificates.CharacteristicPresentation
				+ SelectionOfValidGoodsCertificates.BatchPresentation);
		EndDo;
		
		// Removing items from the collection that have valid item certificates.
		For Each GoodsKeyWithValidCertificates In ArrayOfGoodsKeysWithValidCertificates Do
			GoodsWithoutValidCertificates.Delete(GoodsKeyWithValidCertificates);
		EndDo;
		
		If GoodsWithoutValidCertificates.Count() > 0 Then
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
		EndIf;
		
		For Each KeyAndValue In GoodsWithoutValidCertificates Do
			
			ProductData_8 = KeyAndValue.Value;
			
			GoodsPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
				ProductData_8.ItemName,
				ProductData_8.ItemVariantName,
				,
				ProductData_8.Series,
				AdditionalParametersProductPresentation);
			
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đối với hàng hóa %1 không có chứng nhận có hiệu lực (%2). Cần ghi nhận chứng nhận hàng hóa có hiệu lực.';
					|ru = 'Для товара %1 нет действующих сертификатов (%2). Требуется зарегистрировать действующий сертификат.';
					|en = 'There are no valid certificates (%2) for goods %1. It is required to register a valid certificate.'; fa = 'There are no valid certificates (%2) for goods %1. It is required to register a valid certificate.';
					|it = 'Per il prodotto %1 non ci sono i certificati in vigore (%2). Registrare il certificato in vigore.';
					|pl = 'Dla towaru %1 brak zarejestrowanych certyfikatów (%2). Należy zarejestrować ważny certyfikat.';
					|tr = '%1 öğesinin geçerli sertifikaları mevcut değil (%2). Geçerli bir sertifikanın kaydedilmesi gerekir.'"),
				GoodsPresentation,
				ProductData_8.CertificateType);
			Common.MessageToUser(
				Text,
				ProductData_8.Products);
			
		EndDo;
		
	EndIf;
	
	ReportOnResultsOfVerificationOfOperationOfDocument(ErrorSamplingBusinessOfOperation);
	
	SpreadsheetDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

// Returns the text of the request to get a list of invoices from the transportation task.
//
// The result is placed in the virtual table "Shipping invoices" with columns:
//		Shipping task, delivery address, Waybill, line number.
//
// The request expects the following parameters:
//		Transportation assignments - array of transportation tasks
//		If there are no selected address lines, Boolean is true if there are no selected lines in the TS Routes for the transportation task
//		Highlighted Address lists - an array of numbers of selected lines from TS Routes.
//
// Returns:
//	String - Query string
//
Function TextOfRequestToGetListOfInvoicesFromTransportationTasks() Export
	
	Return 
	"SELECT
	|	TransportationTask.ReferenceOrder,
	|	TransportationTask.Warehouse
	|INTO References
	|FROM
	|	Document.TransportationJob.References AS TransportationTask
	|WHERE
	|	TransportationTask.Ref IN(&TransportationJobs)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DocumentGoods.Ref AS ReferenceOrder
	|FROM
	|	References AS References
	|		INNER JOIN Document.CustomerInvoice.Goods AS DocumentGoods
	|		ON References.ReferenceOrder = DocumentGoods.SalesOrder
	|			AND References.Warehouse = DocumentGoods.Warehouse
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref AS ReferenceOrder
	|FROM
	|	References AS References
	|		INNER JOIN Document.InventoryTransfer.Goods AS DocumentGoods
	|		ON References.ReferenceOrder = DocumentGoods.TransferOrder
	|			AND References.Warehouse = DocumentGoods.Ref.SourceWarehouse
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentGoods.Ref AS ReferenceOrder
	|FROM
	|	References AS References
	|		INNER JOIN Document.TransferOfGoodsToBailee.Goods AS DocumentGoods
	|		ON References.ReferenceOrder = DocumentGoods.SalesOrder
	|			AND References.Warehouse = DocumentGoods.Warehouse
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	References.ReferenceOrder
	|FROM
	|	References AS References
	|WHERE
	|	(References.ReferenceOrder REFS Document.CustomerInvoice
	|		OR References.ReferenceOrder REFS Document.TransferOfGoodsToBailee
	|		OR References.ReferenceOrder REFS Document.InventoryTransfer)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction

Function TextOfRequestForCertificatesOfDocumentProductRange()
	
	QueryText =
	"SELECT
	|	DocumentData.Ref               AS Ref,
	|	DocumentData.Date                 AS Date,
	|	DocumentData.OrderSales  AS ThereAreOrders_,
	|	TableOfGoods.SalesOrder          AS ReferenceOrder,
	|	MAX(TableOfGoods.LineNumber) AS LineNumber,
	|	TableOfGoods.Products          AS Products,
	|	TableOfGoods.Characteristic        AS Characteristic,
	|	TableOfGoods.Series                 AS Series,
	|	CASE
	|		WHEN TableOfGoods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END                                AS SeriesIsIndicatedInInvoice
	|INTO ProductLines_2
	|FROM
	|	Document.CustomerInvoice.Goods AS TableOfGoods
	|		LEFT JOIN Document.CustomerInvoice AS DocumentData
	|		ON TableOfGoods.Ref = DocumentData.Ref
	|WHERE
	|	TableOfGoods.Ref IN(&ObjectsArray)
	|	AND TableOfGoods.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Date,
	|	DocumentData.OrderSales,
	|	TableOfGoods.SalesOrder,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	CASE
	|		WHEN TableOfGoods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref               AS Ref,
	|	DocumentData.Date                 AS Date,
	|	FALSE                                 AS ThereAreOrders_,
	|	UNDEFINED                         AS ReferenceOrder,
	|	MAX(TableOfGoods.LineNumber) AS LineNumber,
	|	TableOfGoods.Products          AS Products,
	|	TableOfGoods.Characteristic        AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	FALSE                                 AS SeriesIsIndicatedInInvoice
	|FROM
	|	Document.SaleAdjustment.Goods AS TableOfGoods
	|		LEFT JOIN Document.SaleAdjustment AS DocumentData
	|		ON TableOfGoods.Ref = DocumentData.Ref
	|WHERE
	|	TableOfGoods.Ref IN(&ObjectsArray)
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Date,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref               AS Ref,
	|	DocumentData.Date                 AS Date,
	|	DocumentData.ShipmentByOrders    AS ThereAreOrders_,
	|	TableOfGoods.SalesOrder          AS ReferenceOrder,
	|	MAX(TableOfGoods.LineNumber) AS LineNumber,
	|	TableOfGoods.Products          AS Products,
	|	TableOfGoods.Characteristic        AS Characteristic,
	|	TableOfGoods.Series                 AS Series,
	|	CASE
	|		WHEN TableOfGoods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END                                AS SeriesIsIndicatedInInvoice
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS TableOfGoods
	|		LEFT JOIN Document.GoodsShipmentToCustomer AS DocumentData
	|		ON TableOfGoods.Ref = DocumentData.Ref
	|WHERE
	|	TableOfGoods.Ref IN(&ObjectsArray)
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Date,
	|	DocumentData.ShipmentByOrders,
	|	TableOfGoods.SalesOrder,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	CASE
	|		WHEN TableOfGoods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref               AS Ref,
	|	DocumentData.Date                 AS Date,
	|	DocumentData.TransferAgainstOrders AS ThereAreOrders_,
	|	TableOfGoods.TransferOrder    AS ReferenceOrder,
	|	MAX(TableOfGoods.LineNumber) AS LineNumber,
	|	TableOfGoods.Products          AS Products,
	|	TableOfGoods.Characteristic        AS Characteristic,
	|	TableOfGoods.Series                 AS Series,
	|	CASE
	|		WHEN TableOfGoods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END                                AS SeriesIsIndicatedInInvoice
	|FROM
	|	Document.InventoryTransfer.Goods AS TableOfGoods
	|		LEFT JOIN Document.InventoryTransfer AS DocumentData
	|		ON TableOfGoods.Ref = DocumentData.Ref
	|WHERE
	|	TableOfGoods.Ref IN(&ObjectsArray)
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Date,
	|	DocumentData.TransferAgainstOrders,
	|	TableOfGoods.TransferOrder,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	CASE
	|		WHEN TableOfGoods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref               AS Ref,
	|	DocumentData.Date                 AS Date,
	|	DocumentData.TransferByOrders    AS ThereAreOrders_,
	|	TableOfGoods.SalesOrder          AS ReferenceOrder,
	|	MAX(TableOfGoods.LineNumber) AS LineNumber,
	|	TableOfGoods.Products          AS Products,
	|	TableOfGoods.Characteristic        AS Characteristic,
	|	TableOfGoods.Series                 AS Series,
	|	CASE
	|		WHEN TableOfGoods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END                                AS SeriesIsIndicatedInInvoice
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS TableOfGoods
	|		LEFT JOIN Document.TransferOfGoodsToBailee AS DocumentData
	|		ON TableOfGoods.Ref = DocumentData.Ref
	|WHERE
	|	TableOfGoods.Ref IN(&ObjectsArray)
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Date,
	|	DocumentData.TransferByOrders,
	|	TableOfGoods.SalesOrder,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	CASE
	|		WHEN TableOfGoods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END
	|
	|INDEX BY
	|	Ref,
	|	ReferenceOrder,
	|	Products,
	|	Characteristic
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	TableOfGoods.Ref                AS Ref,
	|	TableOfGoods.Date                  AS Date,
	|	TableOfGoods.ThereAreOrders_      AS ThereAreOrders_,
	|	TableOfGoods.ReferenceOrder          AS ReferenceOrder,
	|	MAX(TableOfGoods.LineNumber) AS LineNumber,
	|	TableOfGoods.Products          AS Products,
	|	TableOfGoods.Characteristic        AS Characteristic
	|INTO ProductLinesWithoutSeries
	|FROM
	|	ProductLines_2 AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.Ref,
	|	TableOfGoods.Date,
	|	TableOfGoods.ThereAreOrders_,
	|	TableOfGoods.ReferenceOrder,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic
	|
	|INDEX BY
	|	Ref,
	|	ReferenceOrder,
	|	Products,
	|	Characteristic
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	DocumentData.Ref                AS Ref,
	|	FALSE                                  AS KeepRecordsOfQualityCertificates,
	|	DocumentData.BusinessOperation AS BusinessOperation
	|INTO AllDocuments
	|FROM
	|	Document.CustomerInvoice AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                AS Ref,
	|	FALSE                                  AS KeepRecordsOfQualityCertificates,
	|	DocumentData.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.SaleAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                AS Ref,
	|	FALSE                                  AS KeepRecordsOfQualityCertificates,
	|	DocumentData.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.GoodsShipmentToCustomer AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                AS Ref,
	|	FALSE                                  AS KeepRecordsOfQualityCertificates,
	|	DocumentData.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.InventoryTransfer AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsHandover.Ref                AS Ref,
	|	FALSE                                  AS KeepRecordsOfQualityCertificates,
	|	GoodsHandover.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.TransferOfGoodsToBailee AS GoodsHandover
	|WHERE
	|	GoodsHandover.Ref IN(&ObjectsArray)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT DISTINCT
	|	AllDocuments.Ref AS Ref,
	|	MAX(AllDocuments.KeepRecordsOfQualityCertificates) AS KeepRecordsOfQualityCertificates
	|INTO DocumentsAccountingCertificates
	|FROM
	|	(SELECT
	|		ProductLines_2.Ref AS Ref,
	|		ISNULL(Goods.KeepRecordsOfQualityCertificates, FALSE) AS KeepRecordsOfQualityCertificates
	|	FROM
	|		ProductLines_2 AS ProductLines_2
	|			LEFT JOIN Catalog.Products AS Goods
	|			ON ProductLines_2.Products = Goods.Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AllDocuments.Ref AS Ref,
	|		AllDocuments.KeepRecordsOfQualityCertificates AS KeepRecordsOfQualityCertificates
	|	FROM
	|		AllDocuments AS AllDocuments
	|	WHERE
	|		AllDocuments.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|	) AS AllDocuments
	|
	|GROUP BY
	|	AllDocuments.Ref
	|
	|INDEX BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	DocumentsAccountingCertificates.Ref AS Ref
	|INTO DocumentsForWhichCertificatesAreRecorded
	|FROM
	|	DocumentsAccountingCertificates AS DocumentsAccountingCertificates
	|WHERE
	|	DocumentsAccountingCertificates.KeepRecordsOfQualityCertificates
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ProductLines_2.ReferenceOrder AS Ref
	|FROM
	|	DocumentsAccountingCertificates AS DocumentsAccountingCertificates
	|		INNER JOIN ProductLines_2 AS ProductLines_2
	|		ON DocumentsAccountingCertificates.Ref = ProductLines_2.Ref
	|WHERE
	|	DocumentsAccountingCertificates.KeepRecordsOfQualityCertificates
	|	AND ProductLines_2.ThereAreOrders_
	|
	|INDEX BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT DISTINCT
	|	CertificateAccountingDocuments.Ref AS Ref,
	|	GoodsByReferences.Ref      AS WarehouseDocument
	|INTO ExpenditureOrdersOfCertificates
	|FROM
	|	DocumentsForWhichCertificatesAreRecorded AS CertificateAccountingDocuments
	|		INNER JOIN Document.GoodsIssueNote.GoodsByReferences AS GoodsByReferences
	|		ON CertificateAccountingDocuments.Ref = GoodsByReferences.ReferenceOrder
	|
	|INDEX BY
	|	WarehouseDocument
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT DISTINCT
	|	GoodsBatchMovement.Ref         AS Ref,
	|	GoodsBatchMovement.Products   AS Products,
	|	GoodsBatchMovement.Characteristic AS Characteristic,
	|	GoodsBatchMovement.Series          AS Series
	|INTO GoodsBatchMovement
	|FROM
	|	(SELECT
	|		GoodsBatchMovement.Document       AS Ref,
	|		GoodsBatchMovement.Products   AS Products,
	|		GoodsBatchMovement.Characteristic AS Characteristic,
	|		GoodsBatchMovement.Series          AS Series
	|	FROM
	|		DocumentsForWhichCertificatesAreRecorded AS CertificateAccountingDocuments
	|			INNER JOIN AccumulationRegister.GoodsBatchMovement AS GoodsBatchMovement
	|			ON CertificateAccountingDocuments.Ref = GoodsBatchMovement.Document
	|	WHERE
	|		(GoodsBatchMovement.Document REFS Document.CustomerInvoice
	|			OR GoodsBatchMovement.Document REFS Document.TransferOfGoodsToBailee
	|			OR GoodsBatchMovement.Document REFS Document.InventoryTransfer)
	|		AND (CertificateAccountingDocuments.Ref REFS Document.CustomerInvoice
	|			OR CertificateAccountingDocuments.Ref REFS Document.TransferOfGoodsToBailee
	|			OR CertificateAccountingDocuments.Ref REFS Document.InventoryTransfer)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CertificateAccountingDocuments.Ref   AS Ref,
	|		GoodsBatchMovement.Products   AS Products,
	|		GoodsBatchMovement.Characteristic AS Characteristic,
	|		GoodsBatchMovement.Series          AS Series
	|	FROM
	|		ExpenditureOrdersOfCertificates AS CertificateAccountingDocuments
	|			INNER JOIN AccumulationRegister.GoodsBatchMovement AS GoodsBatchMovement
	|			ON CertificateAccountingDocuments.WarehouseDocument = GoodsBatchMovement.Document
	|	WHERE
	|		GoodsBatchMovement.Document REFS Document.GoodsIssueNote) AS GoodsBatchMovement
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 7
	|SELECT
	|	DocumentGoods.Ref					AS Ref,
	|	MAX(DocumentGoods.LineNumber)	AS LineNumber,
	|	DocumentGoods.Date					AS Date,
	|	DocumentGoods.ProductKind			AS ProductKind,
	|	DocumentGoods.Products			AS Products,
	|	DocumentGoods.Characteristic			AS Characteristic,
	|	DocumentGoods.Series AS				Series
	|INTO DocumentGoods
	|FROM
	|	(SELECT
	|		ProductLines_2.Ref         AS Ref,
	|		LinesByNumbers.LineNumber  AS LineNumber,
	|		ProductLines_2.Date           AS Date,
	|		ISNULL(Goods.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef)) AS ProductKind,
	|		ProductLines_2.Products   AS Products,
	|		ProductLines_2.Characteristic AS Characteristic,
	|		ISNULL(GoodsBatchMovement.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series
	|	FROM
	|		ProductLines_2 AS ProductLines_2
	|			INNER JOIN GoodsBatchMovement AS GoodsBatchMovement
	|			ON ProductLines_2.ReferenceOrder = GoodsBatchMovement.Ref
	|				AND ProductLines_2.Products = GoodsBatchMovement.Products
	|				AND ProductLines_2.Characteristic = GoodsBatchMovement.Characteristic
	|			
	|			LEFT JOIN ProductLinesWithoutSeries AS LinesByNumbers
	|			ON ProductLines_2.Ref = LinesByNumbers.Ref
	|				AND ProductLines_2.ReferenceOrder = LinesByNumbers.ReferenceOrder
	|				AND ProductLines_2.Products = LinesByNumbers.Products
	|				AND ProductLines_2.Characteristic = LinesByNumbers.Characteristic
	|			
	|			LEFT JOIN Catalog.Products AS Goods
	|			ON ProductLines_2.Products = Goods.Ref
	|			
	|			INNER JOIN DocumentsForWhichCertificatesAreRecorded AS DocumentsForWhichCertificatesAreRecorded
	|			ON ProductLines_2.Ref = DocumentsForWhichCertificatesAreRecorded.Ref
	|	WHERE
	|		ProductLines_2.ThereAreOrders_
	|		AND NOT ProductLines_2.SeriesIsIndicatedInInvoice
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductLines_2.Ref         AS Ref,
	|		LinesByNumbers.LineNumber  AS LineNumber,
	|		ProductLines_2.Date           AS Date,
	|		ISNULL(Goods.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef)) AS ProductKind,
	|		ProductLines_2.Products   AS Products,
	|		ProductLines_2.Characteristic AS Characteristic,
	|		ISNULL(GoodsBatchMovement.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series
	|	FROM
	|		ProductLines_2 AS ProductLines_2
	|			LEFT JOIN GoodsBatchMovement AS GoodsBatchMovement
	|			ON ProductLines_2.Ref = GoodsBatchMovement.Ref
	|				AND ProductLines_2.Products = GoodsBatchMovement.Products
	|				AND ProductLines_2.Characteristic = GoodsBatchMovement.Characteristic
	|			
	|			LEFT JOIN GoodsBatchMovement AS RegisteredRecordsOfSeriesOfGoodsByOrderOf
	|			ON ProductLines_2.ReferenceOrder = RegisteredRecordsOfSeriesOfGoodsByOrderOf.Ref
	|				AND ProductLines_2.Products = RegisteredRecordsOfSeriesOfGoodsByOrderOf.Products
	|				AND ProductLines_2.Characteristic = RegisteredRecordsOfSeriesOfGoodsByOrderOf.Characteristic
	|			
	|			LEFT JOIN ProductLinesWithoutSeries AS LinesByNumbers
	|			ON ProductLines_2.Ref = LinesByNumbers.Ref
	|				AND ProductLines_2.ReferenceOrder = LinesByNumbers.ReferenceOrder
	|				AND ProductLines_2.Products = LinesByNumbers.Products
	|				AND ProductLines_2.Characteristic = LinesByNumbers.Characteristic
	|			
	|			LEFT JOIN Catalog.Products AS Goods
	|			ON ProductLines_2.Products = Goods.Ref
	|			
	|			INNER JOIN DocumentsForWhichCertificatesAreRecorded AS DocumentsForWhichCertificatesAreRecorded
	|			ON ProductLines_2.Ref = DocumentsForWhichCertificatesAreRecorded.Ref
	|	WHERE
	|		ProductLines_2.ThereAreOrders_
	|		AND NOT ProductLines_2.SeriesIsIndicatedInInvoice
	|		AND RegisteredRecordsOfSeriesOfGoodsByOrderOf.Ref IS NULL
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductLines_2.Ref         AS Ref,
	|		LinesByNumbers.LineNumber  AS LineNumber,
	|		ProductLines_2.Date           AS Date,
	|		ISNULL(Goods.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef)) AS ProductKind,
	|		ProductLines_2.Products   AS Products,
	|		ProductLines_2.Characteristic AS Characteristic,
	|		ISNULL(GoodsBatchMovement.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series
	|	FROM
	|		ProductLines_2 AS ProductLines_2
	|			LEFT JOIN GoodsBatchMovement AS GoodsBatchMovement
	|			ON ProductLines_2.Ref = GoodsBatchMovement.Ref
	|				AND ProductLines_2.Products = GoodsBatchMovement.Products
	|				AND ProductLines_2.Characteristic = GoodsBatchMovement.Characteristic
	|			
	|			LEFT JOIN ProductLinesWithoutSeries AS LinesByNumbers
	|			ON ProductLines_2.Ref = LinesByNumbers.Ref
	|				AND ProductLines_2.ReferenceOrder = LinesByNumbers.ReferenceOrder
	|				AND ProductLines_2.Products = LinesByNumbers.Products
	|				AND ProductLines_2.Characteristic = LinesByNumbers.Characteristic
	|			
	|			LEFT JOIN Catalog.Products AS Goods
	|			ON ProductLines_2.Products = Goods.Ref
	|			
	|			INNER JOIN DocumentsForWhichCertificatesAreRecorded AS DocumentsForWhichCertificatesAreRecorded
	|			ON ProductLines_2.Ref = DocumentsForWhichCertificatesAreRecorded.Ref
	|	WHERE
	|		NOT ProductLines_2.ThereAreOrders_
	|		AND NOT ProductLines_2.SeriesIsIndicatedInInvoice
	|		AND NOT ProductLines_2.Ref REFS Document.SaleAdjustment
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductLines_2.Ref         AS Ref,
	|		LinesByNumbers.LineNumber  AS LineNumber,
	|		ProductLines_2.Date           AS Date,
	|		ISNULL(Goods.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef)) AS ProductKind,
	|		ProductLines_2.Products   AS Products,
	|		ProductLines_2.Characteristic AS Characteristic,
	|		ProductLines_2.Series          AS Series
	|	FROM
	|		ProductLines_2 AS ProductLines_2
	|			LEFT JOIN ProductLinesWithoutSeries AS LinesByNumbers
	|			ON ProductLines_2.Ref = LinesByNumbers.Ref
	|				AND ProductLines_2.ReferenceOrder = LinesByNumbers.ReferenceOrder
	|				AND ProductLines_2.Products = LinesByNumbers.Products
	|				AND ProductLines_2.Characteristic = LinesByNumbers.Characteristic
	|			
	|			LEFT JOIN Catalog.Products AS Goods
	|			ON ProductLines_2.Products = Goods.Ref
	|			
	|			INNER JOIN DocumentsForWhichCertificatesAreRecorded AS DocumentsForWhichCertificatesAreRecorded
	|			ON ProductLines_2.Ref = DocumentsForWhichCertificatesAreRecorded.Ref
	|	WHERE
	|		ProductLines_2.SeriesIsIndicatedInInvoice
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductLines_2.Ref         AS Ref,
	|		ProductLines_2.LineNumber    AS LineNumber,
	|		ProductLines_2.Date           AS Date,
	|		ISNULL(Goods.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef)) AS ProductKind,
	|		ProductLines_2.Products   AS Products,
	|		ProductLines_2.Characteristic AS Characteristic,
	|		ISNULL(GoodsBatchMovement.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series
	|	FROM
	|		ProductLines_2 AS ProductLines_2
	|			LEFT JOIN Document.SaleAdjustment.Goods AS GoodsBatchMovement
	|			ON ProductLines_2.Ref = GoodsBatchMovement.Ref
	|				AND ProductLines_2.Products = GoodsBatchMovement.Products
	|				AND ProductLines_2.Characteristic = GoodsBatchMovement.Characteristic
	|			
	|			LEFT JOIN Catalog.Products AS Goods
	|			ON ProductLines_2.Products = Goods.Ref
	|			
	|			INNER JOIN DocumentsForWhichCertificatesAreRecorded AS DocumentsForWhichCertificatesAreRecorded
	|			ON ProductLines_2.Ref = DocumentsForWhichCertificatesAreRecorded.Ref
	|	WHERE
	|		ProductLines_2.Ref REFS Document.SaleAdjustment
	|
	|	) AS DocumentGoods
	|
	|GROUP BY
	|	DocumentGoods.Ref,
	|	DocumentGoods.Date,
	|	DocumentGoods.ProductKind,
	|	DocumentGoods.Products,
	|	DocumentGoods.Characteristic,
	|	DocumentGoods.Series
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 8
	|SELECT DISTINCT
	|	DocumentGoods.ProductKind AS ProductKind,
	|	DocumentGoods.Products    AS Products,
	|	DocumentGoods.Characteristic  AS Characteristic,
	|	DocumentGoods.Series           AS Series
	|INTO Goods
	|FROM
	|	DocumentGoods AS DocumentGoods
	|		LEFT JOIN Catalog.Products AS ProductData_1
	|		ON DocumentGoods.Products = ProductData_1.Ref
	|WHERE
	|	ISNULL(ProductData_1.KeepRecordsOfQualityCertificates, FALSE)
	|
	|INDEX BY
	|	ProductKind,
	|	Products,
	|	Characteristic,
	|	Series
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 9
	|SELECT
	|	Goods.ProductKind AS ProductKind,
	|	Goods.Products    AS Products,
	|	Goods.Characteristic  AS Characteristic,
	|	Goods.Series           AS Series,
	|	CertificateScopes.QualityCertificate AS QualityCertificate,
	|	CertificateScopes.QualityCertificate.CertificateType AS CertificateType,
	|	MIN(
	|		CASE
	|			WHEN CertificateScopes.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|				THEN 1
	|			WHEN CertificateScopes.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|				THEN 2
	|			WHEN CertificateScopes.Products <> VALUE(Catalog.Products.EmptyRef)
	|				THEN 3
	|			WHEN CertificateScopes.QualityCertificate IS NULL
	|				THEN 0
	|			ELSE 4
	|		END)             AS CertificatePriority,
	|	CASE
	|		WHEN CertificateScopes.QualityCertificate.Status = VALUE(Enum.StatusesOfQualityCertificates.Valid_)
	|			THEN
	|				CASE
	|					WHEN CertificateScopes.QualityCertificate.Permanent
	|						THEN DATETIME(3999, 12, 31, 23, 59, 59)
	|					ELSE CertificateScopes.QualityCertificate.ValidTo
	|				END
	|		ELSE DATETIME(1, 1, 1, 0, 0, 0)
	|	END AS Expiration,
	|	CASE
	|		WHEN CertificateScopes.QualityCertificate.Status = VALUE(Enum.StatusesOfQualityCertificates.Valid_)
	|			THEN CertificateScopes.QualityCertificate.StartDateOfValidityPeriod
	|		ELSE DATETIME(1, 1, 1, 0, 0, 0)
	|	END                  AS StartOfValidityPeriod,
	|	CertificateScopes.QualityCertificate.StatusOfRAC AS StatusOfRAC,
	|	CertificateScopes.QualityCertificate.UpdateDateOfRACStatus AS UpdateDateOfRACStatus
	|INTO ProductsWithCertificates
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN InformationRegister.QualityCertificateApplicationAreas AS CertificateScopes
	|		ON (Goods.ProductKind = CertificateScopes.ProductKind
	|				AND Goods.Products = CertificateScopes.Products
	|				AND Goods.Characteristic = CertificateScopes.Characteristic
	|				AND Goods.Series = CertificateScopes.Series)
	|			OR (Goods.ProductKind = CertificateScopes.ProductKind
	|				AND Goods.Products = CertificateScopes.Products
	|				AND Goods.Characteristic = CertificateScopes.Characteristic
	|				AND CertificateScopes.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			OR (Goods.ProductKind = CertificateScopes.ProductKind
	|				AND Goods.Products = CertificateScopes.Products
	|				AND CertificateScopes.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|				AND CertificateScopes.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			OR (Goods.ProductKind = CertificateScopes.ProductKind
	|				AND CertificateScopes.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|				AND CertificateScopes.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|				AND CertificateScopes.Products = VALUE(Catalog.Products.EmptyRef))
	|WHERE
	|	NOT CertificateScopes.QualityCertificate.DeletionMark
	|
	|GROUP BY
	|	Goods.ProductKind,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	CertificateScopes.QualityCertificate,
	|	CertificateScopes.QualityCertificate.CertificateType,
	|	CASE
	|		WHEN CertificateScopes.QualityCertificate.Status = VALUE(Enum.StatusesOfQualityCertificates.Valid_)
	|			THEN
	|				CASE
	|					WHEN CertificateScopes.QualityCertificate.Permanent
	|						THEN DATETIME(3999, 12, 31, 23, 59, 59)
	|					ELSE CertificateScopes.QualityCertificate.ValidTo
	|				END
	|		ELSE DATETIME(1, 1, 1, 0, 0, 0)
	|	END,
	|	CASE
	|		WHEN CertificateScopes.QualityCertificate.Status = VALUE(Enum.StatusesOfQualityCertificates.Valid_)
	|			THEN CertificateScopes.QualityCertificate.StartDateOfValidityPeriod
	|		ELSE DATETIME(1, 1, 1, 0, 0, 0)
	|	END,
	|	CertificateScopes.QualityCertificate.StatusOfRAC
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series
	|;
	|";
	
	Return QueryText;
	
EndFunction

// Returns the default data for printing information about a product that has invalid certificates.
//
// Returns:
//	Structure - Where:
//		* Products - CatalogRef.Products - Item of the certificate.
//		* ItemName - String -Presentation of the item of the certificate.
//		* ItemVariantName - String - Presentation of the item variant of the certificate.
//		* Series - CatalogRef.ItemsBatches - Certificate item batch.
//		* CertificateType - String - type of item certificate.
//
Function GoodsDataWithNonValidCertificatesForPrinting() Export
	
	ProductData_8 = New Structure;
	ProductData_8.Insert("Products",				Catalogs.Products.EmptyRef());
	ProductData_8.Insert("ItemName",	"");
	ProductData_8.Insert("ItemVariantName",	"");
	ProductData_8.Insert("Series",						Catalogs.ItemsBatches.EmptyRef());
	ProductData_8.Insert("CertificateType",				"");
	
	Return ProductData_8;
	
EndFunction

// Returns the product key for the scope of certificates in the form of a string value consisting of: item,
// characteristics, series.
//
// Parameters:
//	Products - CatalogRef.Products - Item of the certificate.
//	Characteristic - CatalogRef.ItemsCharacteristics - Item variants of the certificate.
//	Series - CatalogRef.ItemsBatches - Certificate item batch.
//
// Returns:
//	String - the key of the product by the scope of the certificates.
//
Function GoodsKeyByCertificateValidityMeasurements(Products, Characteristic, Series) Export
	
	ProductKey = String(Products) + String(Characteristic) + String(Series);
	
	Return ProductKey;
	
EndFunction

Procedure ReportOnResultsOfVerificationOfOperationOfDocument(Selection)
	
	While Selection.Next() Do
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong chứng từ %1 giao dịch kinh tế %2. Không cần in chứng nhận mặt hàng.';
				|ru = 'В документе %1 хозяйственная операция %2. Печать сертификатов номенклатуры не требуется.';
				|en = 'The ""%1"" document has the ""%2"" business transaction. Printing quality certificates is not required.'; fa = 'The ""%1"" document has the ""%2"" business transaction. Printing quality certificates is not required.';
				|it = 'The ""%1"" document has the ""%2"" business transaction. Printing quality certificates is not required.';
				|pl = 'The ""%1"" document has the ""%2"" business transaction. Printing quality certificates is not required.';
				|tr = 'Belge %1ticari işlemdedir%2. Öğe sertifikalarının basılmaları gerekmemektedir.'"),
			Selection.RepresentationOfTheReference,
			Selection.PresentationOfBusinessTransaction);
		Common.MessageToUser(
			Text,
			Selection.Ref);
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
