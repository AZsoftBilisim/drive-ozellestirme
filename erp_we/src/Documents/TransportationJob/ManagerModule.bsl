// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//   GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//   Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnTransportationTask(GenerationCommands);
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	TransportationJobLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "transport Task".
//
// Parameters:
//   GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  - ValueTableRow: See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  - Undefined -
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.TransportationJob) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.TransportationJob.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.TransportationJob);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "NotUseDeliveryManagement25";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	TransportationJobLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#Region StatusChangeChecks

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
//	DocumentsArray - Array - An array of references to documents that should be reviewed
//	NewStatus - String - Name of the new status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.StatusesOfTransportationJobs[NewStatus];
	
	If AdditionalParameters <> Undefined And AdditionalParameters.Property("DeliveryControl") Then
		
		QueryText =
		"SELECT
		|	TaskForTransportationRoute.Ref AS Ref,
		|	MIN(TaskForTransportationRoute.Delivered) AS Delivered
		|INTO
		|	TTRoute
		|FROM
		|	Document.TransportationJob.Route AS TaskForTransportationRoute
		|WHERE
		|	TaskForTransportationRoute.Ref IN (&DocumentsArray)
		|GROUP BY
		|	TaskForTransportationRoute.Ref
		|;
		|SELECT
		|	DocumentsTable.Ref AS Ref,
		|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
		|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
		|	PRESENTATION(&Status) AS PresentationOfNewStatus,
		|	CASE
		|		WHEN TTRoute.Delivered IS NULL 
		|				OR TTRoute.Delivered = TRUE
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreUndeliveredLines,
		|	CASE
		|		WHEN DocumentsTable.Status = &Status
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS StatusMatches,
		|	DocumentsTable.Posted AS Posted,
		|	DocumentsTable.DeletionMark AS DeletionMark,
		|	TRUE AS Recording
		|FROM
		|	Document.TransportationJob AS DocumentsTable
		|LEFT JOIN
		|	TTRoute AS TTRoute
		|ON
		|	TTRoute.Ref = DocumentsTable.Ref
		|WHERE
		|	DocumentsTable.Ref IN(&DocumentsArray)
		|";
		
	Else
		
		QueryText =
		"SELECT
		|	DocumentsTable.Ref AS Ref,
		|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
		|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
		|	PRESENTATION(&Status) AS PresentationOfNewStatus,
		|	CASE
		|		WHEN DocumentsTable.Status = &Status
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS StatusMatches,
		|	DocumentsTable.Posted AS Posted,
		|	DocumentsTable.DeletionMark AS DeletionMark,
		|	TRUE AS Recording
		|FROM
		|	Document.TransportationJob AS DocumentsTable
		|WHERE
		|	DocumentsTable.Ref IN(&DocumentsArray)
		|;";
	
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - String - Name of the new status for documents
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Cancel = False;
	
	If AdditionalParameters = Undefined Then
		Return Not Cancel;
	EndIf;
	
	If AdditionalParameters.Property("DeliveryControl")
		And ValidationSample.ThereAreUndeliveredLines Then
		
		ErrorText = NStr("vi = 'Trong chứng từ %Document% chưa đặt trạng thái ""%Status%"" vì nhiệm vụ chưa được giao đầy đủ';
						|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. задание доставлено не полностью';
						|en = 'Status ""%Status%"" of document %Document% is not set as the job is delivered incompletely'; fa = 'Status ""%Status%"" of document %Document% is not set as the job is delivered incompletely';
						|it = 'Lo stato ""%Status%"" del documento%Document% non è impostato, poiché il task non è trasmesso completamente';
						|pl = 'Dla dokumentu %Document% nie ustawiono ""%Status%"" ponieważ zadanie dostarczono nie w całości';
						|tr = '%Document% belgenin  ""%Status%"" durumu ayarlanmadı, çünkü görev tam olarak teslim edilmedi'");
		ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
		ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
		Common.MessageToUser(ErrorText, ValidationSample.Ref);
		Cancel = True;
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

#EndRegion

// Returns the text of the request to get a list of invoices from the transportation task.
//
// Parameters:
//  GenerateTTOrders	 - Boolean
// 
// Returns:
//  String - Query string
//
Function TextOfRequestToGetListOfInvoicesFromTransportationTasks(GenerateTTOrders) Export

	QueryTexts = New Array; // Array of String
	
	If GenerateTTOrders Then
		
		QueryText =
		"SELECT
		|	TransportationTask.Ref AS TransportationJob,
		|	TransportationTask.ReferenceOrder AS ReferenceOrder,
		|	TransportationTask.Warehouse AS Warehouse,
		|	TransportationTask.Carrier AS CarrierPartner,
		|	TaskForTransportationRoute.Address AS DeliveryAddress,
		|	TaskForTransportationRoute.LineNumber AS RouteLineNumber,
		|	TaskForTransportationRoute.AddressValue AS DeliveryAddressValue,
		|	TaskForTransportationRoute.FieldValueAddress AS DeliveryAddressFieldValues
		|INTO YourRoute
		|FROM
		|	Document.TransportationJob.Route AS TaskForTransportationRoute
		|		INNER JOIN Document.TransportationJob.References AS TransportationTask
		|		ON TaskForTransportationRoute.ConnectionKey = TransportationTask.ConnectionKey
		|			AND TaskForTransportationRoute.Ref = TransportationTask.Ref
		|WHERE
		|	TaskForTransportationRoute.Ref IN(&TransportationJobs)
		|	AND (TaskForTransportationRoute.LineNumber IN (&SelectedAddressStrings)
		|			OR &AllAddressStrings)";
		
		QueryTexts.Add(QueryText);
		
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	References.TransportationJob AS TransportationJob,
	|	References.ReferenceOrder AS ReferenceOrder,
	|	DocumentGoods.Ref AS Invoice,
	|	References.RouteLineNumber AS RouteLineNumber
	|INTO InvoicesForTransportationTasksWithoutAddressFieldValues
	|FROM
	|	YourRoute AS References
	|		INNER JOIN Document.CustomerInvoice.Goods AS DocumentGoods
	|		ON References.ReferenceOrder = DocumentGoods.SalesOrder
	|			AND References.Warehouse = DocumentGoods.Warehouse
	|WHERE
	|	DocumentGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	References.TransportationJob AS TransportationJob,
	|	References.ReferenceOrder AS ReferenceOrder,
	|	DocumentGoods.Ref AS Invoice,
	|	References.RouteLineNumber AS RouteLineNumber
	|FROM
	|	YourRoute AS References
	|		INNER JOIN Document.GoodsShipmentToCustomer.Goods AS DocumentGoods
	|		ON References.ReferenceOrder = DocumentGoods.SalesOrder
	|			AND References.Warehouse = DocumentGoods.Warehouse
	|WHERE
	|	DocumentGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	References.TransportationJob,
	|	References.ReferenceOrder AS ReferenceOrder,
	|	DocumentGoods.Ref,
	|	References.RouteLineNumber
	|FROM
	|	YourRoute AS References
	|		INNER JOIN Document.InventoryTransfer.Goods AS DocumentGoods
	|		ON References.ReferenceOrder = DocumentGoods.TransferOrder
	|			AND References.Warehouse = DocumentGoods.Ref.SourceWarehouse
	|WHERE
	|	DocumentGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	References.TransportationJob  AS TransportationJob,
	|	References.ReferenceOrder        AS ReferenceOrder,
	|	DocumentGoods.Ref            AS Invoice,
	|	References.RouteLineNumber AS RouteLineNumber
	|FROM
	|	YourRoute AS References
	|		INNER JOIN Document.GoodsShipmentFromStorage.Goods AS DocumentGoods
	|		ON References.ReferenceOrder = DocumentGoods.SalesOrder
	|		 AND References.Warehouse = DocumentGoods.Warehouse
	|WHERE
	|	DocumentGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5)
	|	AND DocumentGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	References.TransportationJob,
	|	References.ReferenceOrder AS ReferenceOrder,
	|	DocumentGoods.Ref,
	|	References.RouteLineNumber
	|FROM
	|	YourRoute AS References
	|		INNER JOIN Document.TransferOfGoodsToBailee.Goods AS DocumentGoods
	|		ON References.ReferenceOrder = DocumentGoods.SalesOrder
	|			AND References.Warehouse = DocumentGoods.Warehouse
	|WHERE
	|	DocumentGoods.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	References.TransportationJob,
	|	References.ReferenceOrder,
	|	References.ReferenceOrder,
	|	References.RouteLineNumber
	|FROM
	|	YourRoute AS References
	|WHERE
	|	(References.ReferenceOrder REFS Document.CustomerInvoice
	|			OR References.ReferenceOrder REFS Document.InventoryTransfer
	|			OR References.ReferenceOrder REFS Document.TransferOfGoodsToBailee
	|			OR References.ReferenceOrder REFS Document.GoodsShipmentFromStorage
	|			OR References.ReferenceOrder REFS Document.ReturnOfGoodsToVendor)
	|
	|INDEX BY
	|	Invoice
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoicesForTransportationTasksWithoutAddressFieldValues.TransportationJob AS TransportationJob,
	|	InvoicesForTransportationTasksWithoutAddressFieldValues.Invoice AS Invoice,
	|	InvoicesForTransportationTasksWithoutAddressFieldValues.ReferenceOrder AS ReferenceOrder,
	|	InvoicesForTransportationTasksWithoutAddressFieldValues.RouteLineNumber AS RouteLineNumber,
	|	YourRoute.Warehouse AS Warehouse,
	|	YourRoute.CarrierPartner AS CarrierPartner,
	|	YourRoute.DeliveryAddress AS DeliveryAddress,
	|	YourRoute.DeliveryAddressValue AS DeliveryAddressValue,
	|	YourRoute.DeliveryAddressFieldValues AS DeliveryAddressFieldValues
	|INTO WaybillsForTransportationOrders
	|FROM
	|	InvoicesForTransportationTasksWithoutAddressFieldValues AS InvoicesForTransportationTasksWithoutAddressFieldValues
	|		LEFT JOIN YourRoute AS YourRoute
	|		ON InvoicesForTransportationTasksWithoutAddressFieldValues.TransportationJob = YourRoute.TransportationJob
	|			AND InvoicesForTransportationTasksWithoutAddressFieldValues.RouteLineNumber = YourRoute.RouteLineNumber
	|			AND InvoicesForTransportationTasksWithoutAddressFieldValues.ReferenceOrder = YourRoute.ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP InvoicesForTransportationTasksWithoutAddressFieldValues";
	
	QueryTexts.Add(QueryText);
	
	Return StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Description of the logic of access rights restrictions
//
// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Warehouse)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

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

#EndRegion

#Region Private

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	// Route list
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "OperationSheet";
	PrintCommand.Presentation = NStr("vi = 'Tờ quy trình';
									|ru = 'Маршрутный лист';
									|en = 'Operation sheet'; fa = 'برگه عملیات';
									|it = 'Foglio di lavorazione';
									|pl = 'Karta przebiegu materiału';
									|tr = 'İşlem listesi'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	// Shipping Labels
	PrintCommand = PrintCommands.Add();
	PrintCommand.Handler = "PrintManagementTMClient.PrintingShippingLabels";
	PrintCommand.PrintManager = "DataProcessor.PrintPriceTagsAndLabels.Print";
	PrintCommand.Id = "ShippingLabel";
	PrintCommand.Presentation = NStr("vi = 'Nhãn tem giao hàng';
									|ru = 'Этикетки доставки';
									|en = 'Delivery labels'; fa = 'Delivery labels';
									|it = 'Etichette di consegna';
									|pl = 'Etykiety dostawy';
									|tr = 'Teslimat etiketleri'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	If AccessRight("Read", Metadata.Catalogs.QualityCertificates)
		And GetFunctionalOption("UseQualityCertificates") Then
		// Register of Nomenclature certificates
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CertificatesOfProductsRegister";
		PrintCommand.Presentation = NStr("vi = 'Giấy chứng nhận (đăng ký)';
										|ru = 'Сертификаты (реестр)';
										|en = 'Certificates (registry)'; fa = 'Certificates (registry)';
										|it = 'Certificati (registro)';
										|pl = 'Certyfikaty (rejestr)';
										|tr = 'Sertifikalar (kayıt)'");
		PrintCommand.CheckPostingBeforePrint = True;
		
		// Images of Nomenclature certificates
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CertificatesProductImagesFromDocuments";
		PrintCommand.Presentation = NStr("vi = 'Giấy chứng nhận (cho mỗi mục trong chứng từ)';
										|ru = 'Сертификаты (по каждой позиции документа)';
										|en = 'Certificates (by each document item)'; fa = 'Certificates (by each document item)';
										|it = 'Certificati (per ogni voce del documento)';
										|pl = 'Certyfikaty (dla każdej pozycji dokumentu)';
										|tr = 'Sertifikalar (belgedeki her kalem için)'");
		PrintCommand.CheckPostingBeforePrint = True;
		
		// Images of Nomenclature certificates
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CertificatesProductImagesFromDocumentsWithoutDuplicates";
		PrintCommand.Presentation = NStr("vi = 'Chứng chỉ (một cho mỗi chứng chỉ)';
										|ru = 'Сертификаты (по одному на сертификат)';
										|en = 'Certificates (one per certificate)'; fa = 'Certificates (one per certificate)';
										|it = 'Certificati (uno per certificato)';
										|pl = 'Certyfikaty (po jednym na certyfikat)';
										|tr = 'Sertifikalar (sertifika başına bir tane)'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
	// A set of documents for the printer
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "KitOfDocumentsForPrinter";
	PrintCommand.SkipPreview = True;
	PrintCommand.Presentation = NStr("vi = 'Bộ chứng từ để in';
									|ru = 'Комплект документов на принтер';
									|en = 'Printable document set'; fa = 'Printable document set';
									|it = 'Pacchetto di documenti per la stampa';
									|pl = 'Komplet dokumentów na drukarkę';
									|tr = 'Yazıcı belgeleri seti'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	TransportationJobLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "OperationSheet") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
				PrintFormsCollection,
				"OperationSheet",
				NStr("vi = 'Tờ quy trình';
					|ru = 'Маршрутный лист';
					|en = 'Operation sheet'; fa = 'برگه عملیات';
					|it = 'Foglio di lavorazione';
					|pl = 'Karta przebiegu materiału';
					|tr = 'İşlem listesi'"),
				CreatePrintedFormItinerary(
					ObjectsArray,
					PrintObjects));
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CertificatesOfProductsRegister") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CertificatesOfProductsRegister",
			NStr("vi = 'Giấy chứng nhận (đăng ký)';
				|ru = 'Сертификаты (реестр)';
				|en = 'Certificates (registry)'; fa = 'Certificates (registry)';
				|it = 'Certificati (registro)';
				|pl = 'Certyfikaty (rejestr)';
				|tr = 'Sertifikalar (kayıt)'"),
			Catalogs.QualityCertificates.CreatePrintedFormRegisterOfProductCertificates(ObjectsArray, PrintObjects),
			,
			"Catalog.QualityCertificates.PF_MXL_CertificateRegistry");
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CertificatesProductImagesFromDocuments") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CertificatesProductImagesFromDocuments",
			NStr("vi = 'Giấy chứng nhận (cho mỗi mục trong chứng từ)';
				|ru = 'Сертификаты (по каждой позиции документа)';
				|en = 'Certificates (by each document item)'; fa = 'Certificates (by each document item)';
				|it = 'Certificati (per ogni voce del documento)';
				|pl = 'Certyfikaty (dla każdej pozycji dokumentu)';
				|tr = 'Sertifikalar (belgedeki her kalem için)'"),
			Catalogs.QualityCertificates.GeneratePrintedFormImagesOfCertificatesFromDocuments(ObjectsArray, PrintObjects),
			,
			"Catalog.QualityCertificates.PF_MXL_CertificateImages");
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CertificatesProductImagesFromDocumentsWithoutDuplicates") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CertificatesProductImagesFromDocumentsWithoutDuplicates",
			NStr("vi = 'Chứng chỉ (một cho mỗi chứng chỉ)';
				|ru = 'Сертификаты (по одному на сертификат)';
				|en = 'Certificates (one per certificate)'; fa = 'Certificates (one per certificate)';
				|it = 'Certificati (uno per certificato)';
				|pl = 'Certyfikaty (po jednym na certyfikat)';
				|tr = 'Sertifikalar (sertifika başına bir tane)'"),
			Catalogs.QualityCertificates.GeneratePrintedFormImagesOfCertificatesFromDocumentsWithoutDuplicates(ObjectsArray, PrintObjects),
			,
			"Catalog.QualityCertificates.PF_MXL_CertificateImages");
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "KitOfDocumentsForPrinter") Then
		CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects);
	EndIf;
	
	TransportationJobLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

Function CreatePrintedFormItinerary(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PageOrientation  = PageOrientation.Landscape;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_TransportationJob_OperationSheet";
	
	Template = PrintManagement.PrintFormTemplate("Document.TransportationJob.PF_MXL_OperationSheet");
	
	DocumentHeaderArea		= Template.GetArea("DocumentTitle");
	DocumentHeaderArea_ 			= Template.GetArea("DocumentHeader");
	AreaAdditionalInformation = Template.GetArea("AdditionalInformation");
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	ExpenseOrder.Ref AS WarehouseDocument,
	|	TaskManager.ReferenceOrder AS ReferenceOrder
	|INTO OrdersForRecipients
	|FROM
	|	Document.TransportationJob.References AS TaskManager
	|		LEFT JOIN Document.GoodsIssueNote AS ExpenseOrder
	|		ON TaskManager.Ref = ExpenseOrder.TransportationJob
	|			AND TaskManager.RecipientSender = ExpenseOrder.Recipient
	|			AND (NOT ExpenseOrder.DeletionMark)
	|WHERE
	|	TaskManager.Ref IN(&ObjectsArray)
	|
	|INDEX BY
	|	ExpenseOrder.Ref,
	|	TaskManager.ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TaskManager.Ref AS Job,
	|	TaskManager.ReferenceOrder AS ReferenceOrder,
	|	ISNULL(OrdersOrders_.Ref, VALUE(Document.GoodsIssueNote.EmptyRef)) AS WarehouseDocument
	|INTO TaskOrders
	|FROM
	|	Document.TransportationJob.References AS TaskManager
	|		LEFT JOIN Document.GoodsIssueNote.GoodsByReferences AS OrdersOrders_
	|		ON TaskManager.ReferenceOrder = OrdersOrders_.ReferenceOrder
	|			AND (NOT OrdersOrders_.Ref.DeletionMark)
	|WHERE
	|	TaskManager.Ref IN(&ObjectsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaskManager.Ref AS Ref,
	|	TaskManager.RecipientSender AS Recipient,
	|	TaskManager.ReferenceOrder AS ReferenceOrder,
	|	TaskManager.ConnectionKey AS ConnectionKey,
	|	TaskManager.LineNumber AS LineNumber,
	|	TaskManager.Weight AS Weight,
	|	TaskManager.VolumeM3 AS VolumeM3,
	|	ISNULL(SUM(ShippedGoods.NumberOfPackages), 0) AS NumberOfSeats
	|INTO OrdersOrders_
	|FROM
	|	Document.TransportationJob.References AS TaskManager
	|		LEFT JOIN TaskOrders AS TaskOrders
	|		ON TaskManager.Ref = TaskOrders.Job
	|			AND TaskManager.ReferenceOrder = TaskOrders.ReferenceOrder
	|		LEFT JOIN Document.GoodsIssueNote.ShippedGoods AS ShippedGoods
	|		ON (TaskOrders.WarehouseDocument = ShippedGoods.Ref)
	|			AND (ShippedGoods.PackingListParent = VALUE(Document.PackingList.EmptyRef))
	|WHERE
	|	TaskManager.Ref IN(&ObjectsArray)
	|
	|GROUP BY
	|	TaskManager.Ref,
	|	TaskManager.RecipientSender,
	|	TaskManager.ReferenceOrder,
	|	TaskManager.ConnectionKey,
	|	TaskManager.LineNumber,
	|	TaskManager.Weight,
	|	TaskManager.VolumeM3
	|
	|INDEX BY
	|	TaskManager.ConnectionKey,
	|	TaskManager.ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TransportationJob.Ref AS Ref,
	|	TransportationJob.Number AS JobNumber,
	|	TransportationJob.Date AS Date,
	|	PRESENTATION(TransportationJob.Driver) AS Driver_Name,
	|	TransportationJob.DriverFullName AS Driver,
	|	PRESENTATION(TransportationJob.CourierShippingAgent) AS CourierShippingAgent,
	|	PRESENTATION(TransportationJob.Vehicle_) AS VehicleName,
	|	TRIMALL(TransportationJob.VehicleRegPlate) + "" "" + TRIMALL(TransportationJob.VehicleModel) AS Vehicle_,
	|	TransportationJob.Priority AS Priority,
	|	TransportationJob.PlanTripStartTime AS TripStartPlan,
	|	TransportationJob.PlanTripEndTime AS TripEndPlan,
	|	TransportationJob.ActualTripStartTime AS TripStartActual,
	|	TransportationJob.ActualTripEndTime AS TripEndActual,
	|	TransportationJob.AdditionalInformation AS AdditionalInformation_3,
	|	TransportationJob.Weight AS TotalWeight_,
	|	TransportationJob.VolumeM3 AS TotalVolume
	|FROM
	|	Document.TransportationJob AS TransportationJob
	|WHERE
	|	TransportationJob.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	TransportationJob.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaskRoute.Ref AS Ref,
	|	TaskRoute.Address AS Address,
	|	TaskRoute.Zone AS Zone,
	|	TaskRoute.TimeFrom AS TimeFrom,
	|	TaskRoute.TimeTo AS TimeTo,
	|	CAST(TaskRoute.AdditionalInformation AS STRING(1000)) AS AdditionalInformation,
	|	OrdersOrders_.Recipient AS Recipient,
	|	OrdersOrders_.ReferenceOrder AS ReferenceOrder,
	|	OrdersOrders_.ReferenceOrder.Number AS TheNumberOfTheOrder,
	|	SUM(OrdersOrders_.Weight) AS Weight,
	|	SUM(OrdersOrders_.VolumeM3) AS VolumeM3,
	|	OrdersOrders_.NumberOfSeats AS NumberOfSeats
	|FROM
	|	Document.TransportationJob.Route AS TaskRoute
	|		LEFT JOIN OrdersOrders_ AS OrdersOrders_
	|		ON TaskRoute.ConnectionKey = OrdersOrders_.ConnectionKey
	|WHERE
	|	TaskRoute.Ref IN(&ObjectsArray)
	|
	|GROUP BY
	|	TaskRoute.Ref,
	|	TaskRoute.LineNumber,
	|	TaskRoute.ConnectionKey,
	|	TaskRoute.Address,
	|	TaskRoute.Zone,
	|	TaskRoute.TimeFrom,
	|	TaskRoute.TimeTo,
	|	CAST(TaskRoute.AdditionalInformation AS STRING(1000)),
	|	OrdersOrders_.Recipient,
	|	OrdersOrders_.ReferenceOrder,
	|	OrdersOrders_.ReferenceOrder.Number,
	|	OrdersOrders_.NumberOfSeats
	|
	|ORDER BY
	|	TaskRoute.Ref,
	|	TaskRoute.LineNumber,
	|	MIN(OrdersOrders_.LineNumber)
	|TOTALS BY
	|	Ref,
	|	TaskRoute.LineNumber,
	|	TaskRoute.ConnectionKey,
	|	Recipient
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	References.Warehouse AS Warehouse,
	|	References.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|		AND References.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= References.ReferenceOrder.Date AS AdvancedWarehousingOnShipment
	|FROM
	|	Document.TransportationJob.References AS References
	|WHERE
	|	References.Ref IN(&ObjectsArray)
	|	AND NOT References.Warehouse.IsFolder";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	ResultOfRequestForDocument = Query.ExecuteBatch(); 
	
	ResultDocumentHeader = ResultOfRequestForDocument[3].Select();
	SelectionByRefs         = ResultOfRequestForDocument[4].Select(QueryResultIteration.ByGroups);
	WarehousesLoadingSample    = ResultOfRequestForDocument[5].Select();
	
	FirstDocument = True;
	
	While ResultDocumentHeader.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		DocumentAttributes = New Structure;
		DocumentAttributes.Insert("Number", ResultDocumentHeader.JobNumber);
		DocumentAttributes.Insert("Date",  ResultDocumentHeader.Date);
		
		DocumentName_1 = NStr("vi = 'Tờ quy trình';
								|ru = 'Маршрутный лист';
								|en = 'Operation sheet'; fa = 'برگه عملیات';
								|it = 'Foglio di lavorazione';
								|pl = 'Karta przebiegu materiału';
								|tr = 'İşlem listesi'", Common.DefaultLanguageCode());
		
		DocumentTitle = TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes,
																							DocumentName_1);
		DocumentHeaderArea.Parameters.DocumentTitle = DocumentTitle;
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument,
																		Template,
																		DocumentHeaderArea,
																		ResultDocumentHeader.Ref);
		
		SpreadsheetDocument.Put(DocumentHeaderArea);
		
		DocumentHeaderArea_.Parameters.Fill(ResultDocumentHeader);
		
		LoadingWarehousesLine = "";
		ThereAreAdvancedWarehouses   = False;
		
		While WarehousesLoadingSample.Next() Do
			If WarehousesLoadingSample.AdvancedWarehousingOnShipment
				And Not ThereAreAdvancedWarehouses Then
				
				ThereAreAdvancedWarehouses = True;
				
			EndIf;
			
			LoadingWarehousesLine = LoadingWarehousesLine + WarehousesLoadingSample.Warehouse + "," + Chars.NBSp;
		EndDo;
		
		AreaSuffix = ?(Not ThereAreAdvancedWarehouses, "WithoutPlace", "");
		
		Area_TableHeader		= Template.GetArea("TableHeader" + AreaSuffix);
		AreaTableRow	= Template.GetArea("TableRow" + AreaSuffix);
		ScopeOfAdditionalRowOfTable	= Template.GetArea("AdditionalTableRow" + AreaSuffix);
		TableBasementArea 	= Template.GetArea("TableFooter" + AreaSuffix);
		AreaResults 			= Template.GetArea("Totals" + AreaSuffix);
		
		If LoadingWarehousesLine <> "" Then
			LoadingWarehousesLine = Left(LoadingWarehousesLine, StrLen(LoadingWarehousesLine) - 2);
			
			DocumentHeaderArea_.Parameters.LadingWarehouses = LoadingWarehousesLine;
		EndIf;
		
		If IsBlankString(DocumentHeaderArea_.Parameters.Vehicle_) Then
			DocumentHeaderArea_.Parameters.Vehicle_ = ResultDocumentHeader.VehicleName;
		EndIf;
		
		SpreadsheetDocument.Put(DocumentHeaderArea_);
		
		SearchSelection = New Structure ("Ref", ResultDocumentHeader.Ref);
		
		While SelectionByRefs.FindNext(SearchSelection) Do
			
			ColumnNameWeight   = NStr("vi = 'Trọng lượng, %UnitOfMeasurementWeight%';
										|ru = 'Вес, %UnitOfMeasurementWeight%';
										|en = 'Weight, %UnitOfMeasurementWeight%'; fa = 'Weight, %UnitOfMeasurementWeight%';
										|it = 'Peso, %UnitOfMeasurementWeight%';
										|pl = 'Waga, %UnitOfMeasurementWeight%';
										|tr = 'Ağırlık, %UnitOfMeasurementWeight%'", Common.DefaultLanguageCode());
			ColumnNameVolume = NStr("vi = 'Khối lượng, %UnitOfMeasurementVolume%';
									|ru = 'Объем, %UnitOfMeasurementVolume%';
									|en = 'Volume, %UnitOfMeasurementVolume%'; fa = 'Volume, %UnitOfMeasurementVolume%';
									|it = 'Volume, %UnitOfMeasurementVolume%';
									|pl = 'Objętość, %UnitOfMeasurementVolume%';
									|tr = 'Hacim, %UnitOfMeasurementVolume%'", Common.DefaultLanguageCode());
			
			ColumnNameWeight   = StrReplace(ColumnNameWeight,
										"%UnitOfMeasurementWeight%",
										Constants.UnitOfMeasureForWeight.Get());
			ColumnNameVolume = StrReplace(ColumnNameVolume,
										"%UnitOfMeasurementVolume%",
										Constants.UnitOfMeasureForVolume.Get());
			
			TableColumnNames = New Structure("WeightCap, VolumeHeader_", ColumnNameWeight, ColumnNameVolume);
			
			Area_TableHeader.Parameters.Fill(TableColumnNames);
			
			SpreadsheetDocument.Put(Area_TableHeader);
			
			SamplingByRowNumbers = SelectionByRefs.Select(QueryResultIteration.ByGroups);
			
			LineNumber = 0;
			TotalNumberOfSeats = 0;
			
			While SamplingByRowNumbers.Next() Do
			
				SelectionByLineCodes = SamplingByRowNumbers.Select(QueryResultIteration.ByGroups);
				
				While SelectionByLineCodes.Next() Do
					
					LineNumber = LineNumber + 1;
					
					AreaTableRow.Parameters.OrderNumber = LineNumber;
					
					SelectionByRecipients = SelectionByLineCodes.Select(QueryResultIteration.ByGroups);
					
					FirstRecipient = True;
					
					NumberOfRecipients = SelectionByRecipients.Count() - 1;
					
					While SelectionByRecipients.Next() Do
						
						If FirstRecipient Then
							FirstRecipient = False;
							
							AreaToFillIn = AreaTableRow;
						Else
							AreaToFillIn = ScopeOfAdditionalRowOfTable;
						EndIf;
						
						TotalWeight_   = 0;
						TotalVolume = 0;
						
						NumberOfPlacesPerLine = 0;
						
						References = New Map;
						
						Selection = SelectionByRecipients.Select();
						
						While Selection.Next() Do
							TotalWeight_   = TotalWeight_ + Selection.Weight;
							TotalVolume = TotalVolume + Selection.VolumeM3;
							
							NumberOfPlacesPerLine = Selection.NumberOfSeats;
							
							AreaToFillIn.Parameters.Fill(Selection);
							
							OrderLine_2 = References.Get(Selection.ReferenceOrder.Metadata());
							
							If OrderLine_2 = Undefined Then
								OrderLine_2 = Selection.ReferenceOrder.Metadata().ListPresentation + ": "
													+ ObjectsPrefixesClientServer.NumberForPrinting(Selection.TheNumberOfTheOrder);
							Else
								OrderLine_2 = OrderLine_2 + "," + " "
									+ ObjectsPrefixesClientServer.NumberForPrinting(Selection.ReferenceOrder.Number);
							EndIf;
							
							References.Insert(Selection.ReferenceOrder.Metadata(), OrderLine_2);
						EndDo;
						
						TotalNumberOfSeats = TotalNumberOfSeats + NumberOfPlacesPerLine;
						
						OrderNames = "";
						
						For Each OrderKeyValue In References Do
							OrderNames = OrderNames + OrderKeyValue.Value + Chars.LF;
						EndDo;
						
						RecipientSCargoParameters = New Structure;
						RecipientSCargoParameters.Insert("References",   OrderNames);
						RecipientSCargoParameters.Insert("Weight",            TotalWeight_);
						RecipientSCargoParameters.Insert("VolumeM3",          TotalVolume);
						RecipientSCargoParameters.Insert("NumberOfSeats", NumberOfPlacesPerLine);
						
						AreaToFillIn.Parameters.Fill(RecipientSCargoParameters);
						
						SpreadsheetDocument.Put(AreaToFillIn);
						
					EndDo;
					
					MergeAreaWithLinesBelow(SpreadsheetDocument,
													"OrderNumber" + AreaSuffix,
													NumberOfRecipients);
					MergeAreaWithLinesBelow(SpreadsheetDocument,
													"Address" + AreaSuffix,
													NumberOfRecipients);
					MergeAreaWithLinesBelow(SpreadsheetDocument,
													"Zone" + AreaSuffix,
													NumberOfRecipients);
					MergeAreaWithLinesBelow(SpreadsheetDocument,
													"TimeFrom" + AreaSuffix,
													NumberOfRecipients);
					MergeAreaWithLinesBelow(SpreadsheetDocument,
													"TimeTo" + AreaSuffix,
													NumberOfRecipients);
					MergeAreaWithLinesBelow(SpreadsheetDocument,
													"AdditionalInformationRow" + AreaSuffix,
													NumberOfRecipients);
					
				EndDo;
			
			EndDo;
			
			SpreadsheetDocument.Put(TableBasementArea);
			
			DocumentWeight_   = ResultDocumentHeader.TotalWeight_
								/ ProductsServer.TonConversionFactor(Constants.UnitOfMeasureForWeight.Get());
			VolumePerDocument = ResultDocumentHeader.TotalVolume
								/ ProductsServer.CubicMeterConversionFactor(Constants.UnitOfMeasureForVolume.Get());
			
			TotalsParameters = New Structure;
			TotalsParameters.Insert("TotalWeight_",   DocumentWeight_);
			TotalsParameters.Insert("TotalVolume", VolumePerDocument);
			
			If ThereAreAdvancedWarehouses Then
				TotalsParameters.Insert("TotalNumberOfSeats", TotalNumberOfSeats);
			EndIf;
			
			AreaResults.Parameters.Fill(TotalsParameters);
			
			SpreadsheetDocument.Put(AreaResults);
			
			If ValueIsFilled(ResultDocumentHeader.AdditionalInformation_3) Then
				AreaAdditionalInformation.Parameters.AdditionalInformation_3 = TrimAll(ResultDocumentHeader.AdditionalInformation_3);
				
				SpreadsheetDocument.Put(AreaAdditionalInformation);
			EndIf;
			
		EndDo;
		
		PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument,
			RowNumberStart,
			PrintObjects,
			ResultDocumentHeader.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

Procedure MergeAreaWithLinesBelow(SpreadsheetDocument, AreaName, NumberOfAdditionalRows)
	
	If NumberOfAdditionalRows < 1 Then
		Return
	EndIf;
	
	Area = SpreadsheetDocument.Area(AreaName);
	
	Area.UndoMerge();
	
	Area.Name = Undefined;
	
	AddressOfRegion = Area.Name;
	
	ArrayAreaAddress = StrSplit(AddressOfRegion, ":");
	
	If ArrayAreaAddress.Count() = 1 Then
		ArrayAreaAddress.Add(ArrayAreaAddress[0]);
	EndIf;
	
	EndAddress       = ArrayAreaAddress[1];
	ArrayEndAddress = StrSplit(EndAddress, "C");
	LastLineNumberLine = Mid(ArrayEndAddress[0], 2);
	NewLastLineNumber = String(Number(LastLineNumberLine) + NumberOfAdditionalRows);
	NewLastLineNumber = StrReplace(NewLastLineNumber, Chars.NBSp, "");
	NewAddress = ArrayAreaAddress[0] + ":R" + NewLastLineNumber + "C" + ArrayEndAddress[1];
	
	Area = SpreadsheetDocument.Area(NewAddress);
	
	Area.Merge();
	
EndProcedure

// Create printed forms of objects.
//
// Parameters:
//	ObjectsArray        - Array           - an array of references to objects which need to print,
//	PrintParameters       - Structure        - structure of additional print parameters,
//	PrintFormsCollection - ValueTable  - generated table documents,
//	PrintObjects         - ValueList   - list of print objects.
//
Procedure CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects) Export
	
	PrintFormsCollection.Clear();
	
	NewRow = PrintFormsCollection.Add();
	NewRow.TemplateName = "OperationSheet";
	NewRow.Copies2 = 1;
	NewRow.UpperCaseName = Upper(NewRow.TemplateName);
	
	PrintManagement.OutputSpreadsheetDocumentToCollection(
				PrintFormsCollection,
				"OperationSheet",
				NStr("vi = 'Tờ quy trình';
					|ru = 'Маршрутный лист';
					|en = 'Operation sheet'; fa = 'برگه عملیات';
					|it = 'Foglio di lavorazione';
					|pl = 'Karta przebiegu materiału';
					|tr = 'İşlem listesi'"),
				CreatePrintedFormItinerary(ObjectsArray, PrintObjects));
				
	ArrayOfInvoices = GetInvoicesForTransportationOrder(ObjectsArray);			
					
	For Each Map In Common.ObjectsAttributesValues(ArrayOfInvoices, "Posted") Do
		If Not Map.Value.Posted Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chứng từ %1 chưa kết chuyển. Sẽ không in bộ chứng từ theo chứng từ này.';
					|ru = 'Документ %1 не проведен. Печать комплекта по этому документу не будет выполнена.';
					|en = 'Document %1 is not posted. The document set will not be printed.'; fa = 'Document %1 is not posted. The document set will not be printed.';
					|it = 'Il documento %1 non è stato registrato. La stampa del set per questo documento non verrà eseguita.';
					|pl = 'Dokument %1 nie jest zatwierdzony. Drukowanie kompletu według tego dokumentu nie jest wykonane.';
					|tr = 'Belge %1kaydedilmedi. Bu belge set halinde yazdırılmayacaktır.'"),
				Map.Key);
			CommonClientServer.MessageToUser(
				Text,
				Map.Key);
			ArrayOfInvoices.Delete(ArrayOfInvoices.Find(Map.Key));
		EndIf;
	EndDo;
	
	MapTypes = TMCommonUse.MatchingArraysByObjectType(ArrayOfInvoices);
	
	For Each CurObjectType In MapTypes Do
		
		PrintManager = Common.ObjectManagerByFullName(CurObjectType.Key);
		PrintManager.CreateSetOfPrintedForms(
			CurObjectType.Value,
			PrintParameters,
			PrintFormsCollection,
			PrintObjects);
		
	EndDo;
	
	SortPrintedFormsByCounterparty(ArrayOfInvoices, PrintObjects);
	
EndProcedure

Procedure SortPrintedFormsByCounterparty(ArrayOfInvoices, PrintObjects)
	
	ArrayOfCounterparties = New Array; // Array of CatalogRef.Counterparties
	
	For Each CurDocument In ArrayOfInvoices Do
		
		Try
			InvoiceCounterparty = Common.ObjectAttributeValue(CurDocument, "Counterparty"); // CatalogRef.Counterparties
			ArrayOfCounterparties.Add(InvoiceCounterparty);
		Except
		EndTry;
		
	EndDo;
	
	DocumentsTable = New ValueTable();
	DocumentsTable.Columns.Add("Counterparty");
	DocumentsTable.Columns.Add("Document");
	
	For Each DocumentLine In PrintObjects Do
			Try
				TableRow = DocumentsTable.Add();
				TableRow.Document = DocumentLine.Value;
				TableRow.Counterparty = Common.ObjectAttributeValue(DocumentLine.Value, "Counterparty");
			Except
			EndTry;
	EndDo;
	
	RowIndex = 1;
	For Each CurCounterparty In ArrayOfCounterparties Do
		
		FilterByCounterparty = New Structure();
		FilterByCounterparty.Insert("Counterparty", CurCounterparty);
		DocumentsOnCounterparty = DocumentsTable.FindRows(FilterByCounterparty);
		For Each DocumentLine In DocumentsOnCounterparty Do
			NewRow = DocumentsTable.Insert(RowIndex);
			FillPropertyValues(NewRow, DocumentLine);
			DocumentsTable.Delete(DocumentLine);
			RowIndex = RowIndex + 1;
		EndDo;
		
	EndDo;
	
	For Each RowOfCounterparty In DocumentsTable Do
		PrintObject = PrintObjects.FindByValue(RowOfCounterparty.Document);
		PrintObjects.Delete(PrintObject);
		PrintObjects.Add(PrintObject.Value, PrintObject.Presentation);
	EndDo;
	
EndProcedure

Function GetInvoicesForTransportationOrder(ObjectsArray) Export
	
	Query = New Query;
	Query.Text = TextOfRequestToGetListOfInvoicesFromTransportationTasks(True);
	Query.SetParameter("TransportationJobs", 		ObjectsArray);
	Query.SetParameter("AllAddressStrings", 	True);
	Query.SetParameter("SelectedAddressStrings",	New Array);
	
	QueryResult = Query.ExecuteBatchWithIntermediateData();
	
	ResultTable1 = QueryResult[QueryResult.UBound()-1].Unload();
	
	ResultTable1.GroupBy("Invoice");
	
	Return ResultTable1.UnloadColumn("Invoice");
	
EndFunction

#EndRegion

#Region Other

// Creates a queue for reissuing spending orders for the task.
//
// Parameters:
// 	TransportationJob - DocumentRef.TransportationJob - the task.
// 	Cancel - Boolean - a sign of failure.
// 	ChangesInCompositionOfOrders - ValueTable - table of changes in the composition of orders.
//
Procedure CreateQueueForReissuingSpendingOrders(TransportationJob, Cancel, ChangesInCompositionOfOrders = Undefined) Export
		
	Query = New Query;
	Query.Text = TextOfRegisterControlRequestGoodsForShipmentAndGoodsForDelivery() +
	"SELECT
	|	GoodsForIssueBalance.DocumentShipments,
	|	GoodsForIssueBalance.Warehouse,
	|	GoodsForIssueBalance.Recipient,
	|	GoodsForIssueBalance.Products,
	|	GoodsForIssueBalance.Characteristic,
	|	GoodsForIssueBalance.Purpose,
	|	GoodsForIssueBalance.Series,
	|	SUM(GoodsForIssueBalance.ToShipReceipt) AS ToShipReceipt,
	|	SUM(GoodsForIssueBalance.ToShipExpense) AS ToShipExpense,
	|	SUM(GoodsForIssueBalance.CollectedRemainderIsCollected) AS CollectedRemainderIsCollected,
	|	SUM(GoodsForIssueBalance.ForAssemblyBalance) AS ForAssemblyBalance
	|INTO GoodsForIssueBalance
	|FROM
	|	(SELECT
	|		GoodsForShipmentAndDelivery.DocumentShipments AS DocumentShipments,
	|		GoodsForShipmentAndDelivery.Warehouse AS Warehouse,
	|		GoodsForShipmentAndDelivery.Recipient AS Recipient,
	|		GoodsForShipmentAndDelivery.Products AS Products,
	|		GoodsForShipmentAndDelivery.Characteristic AS Characteristic,
	|		GoodsForShipmentAndDelivery.Purpose AS Purpose,
	|		GoodsForShipmentAndDelivery.Series AS Series,
	|		CASE
	|			WHEN GoodsForShipmentAndDelivery.Count < GoodsForShipmentAndDelivery.QuantityToShip
	|				THEN GoodsForShipmentAndDelivery.Count
	|			ELSE GoodsForShipmentAndDelivery.QuantityToShip
	|		END AS ToShipReceipt,
	|		0 AS ToShipExpense,
	|		0 AS CollectedRemainderIsCollected,
	|		0 AS ForAssemblyBalance
	|	FROM
	|		GoodsForShipmentAndDelivery AS GoodsForShipmentAndDelivery
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsForIssueExpense.DocumentShipments,
	|		GoodsForIssueExpense.Warehouse,
	|		GoodsForIssueExpense.Recipient,
	|		GoodsForIssueExpense.Products,
	|		GoodsForIssueExpense.Characteristic,
	|		GoodsForIssueExpense.Purpose,
	|		GoodsForIssueExpense.Series,
	|		0,
	|		GoodsForIssueExpense.Count,
	|		0,
	|		0
	|	FROM
	|		GoodsForIssueExpense AS GoodsForIssueExpense
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsCollectedCollected_.DocumentShipments,
	|		GoodsCollectedCollected_.Warehouse,
	|		GoodsCollectedCollected_.Recipient,
	|		GoodsCollectedCollected_.Products,
	|		GoodsCollectedCollected_.Characteristic,
	|		GoodsCollectedCollected_.Purpose,
	|		GoodsCollectedCollected_.Series,
	|		0,
	|		0,
	|		GoodsCollectedCollected_.Count,
	|		0
	|	FROM
	|		GoodsCollectedCollected_ AS GoodsCollectedCollected_
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductsReadyForAssembly.DocumentShipments,
	|		ProductsReadyForAssembly.Warehouse,
	|		ProductsReadyForAssembly.Recipient,
	|		ProductsReadyForAssembly.Products,
	|		ProductsReadyForAssembly.Characteristic,
	|		ProductsReadyForAssembly.Purpose,
	|		ProductsReadyForAssembly.Series,
	|		0,
	|		0,
	|		0,
	|		ProductsReadyForAssembly.Count
	|	FROM
	|		ProductsReadyForAssembly AS ProductsReadyForAssembly) AS GoodsForIssueBalance
	|
	|GROUP BY
	|	GoodsForIssueBalance.DocumentShipments,
	|	GoodsForIssueBalance.Warehouse,
	|	GoodsForIssueBalance.Recipient,
	|	GoodsForIssueBalance.Products,
	|	GoodsForIssueBalance.Characteristic,
	|	GoodsForIssueBalance.Purpose,
	|	GoodsForIssueBalance.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	GoodsForIssueBalance.Warehouse,
	|	GoodsForIssueBalance.Recipient
	|FROM
	|	GoodsForIssueBalance AS GoodsForIssueBalance
	|WHERE
	|	GoodsForIssueBalance.ToShipReceipt - GoodsForIssueBalance.ToShipExpense - GoodsForIssueBalance.CollectedRemainderIsCollected > GoodsForIssueBalance.ForAssemblyBalance
	|			OR GoodsForIssueBalance.ForAssemblyBalance > 0 AND
	|	GoodsForIssueBalance.ToShipReceipt - GoodsForIssueBalance.ToShipExpense - GoodsForIssueBalance.CollectedRemainderIsCollected < GoodsForIssueBalance.ForAssemblyBalance";
	
	IssueInvoicesFirst = Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get() = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst;
	Query.SetParameter("IssueInvoicesFirst", IssueInvoicesFirst);
	Query.SetParameter("TransportationJob", TransportationJob); 
	WarehouseAndRecipientForReissuingOrders = Query.Execute().Unload();
	
	If ValueIsFilled(ChangesInCompositionOfOrders) Then
		CommonClientServer.SupplementTable(ChangesInCompositionOfOrders, WarehouseAndRecipientForReissuingOrders);
		WarehouseAndRecipientForReissuingOrders.GroupBy("Warehouse, Recipient");
	EndIf;
	
	DocumentDate = Common.ObjectAttributeValue(TransportationJob, "Date");
	
	For Each String In WarehouseAndRecipientForReissuingOrders Do
		
		If Not WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(String.Warehouse, DocumentDate) Then
			Continue;
		EndIf;
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.GoodsIssueNoteReregistrationQueue");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("Warehouse", String.Warehouse);
		LockItem.SetValue("Recipient", String.Recipient);
		Block.Lock();
		
		QueueRecordset = InformationRegisters.GoodsIssueNoteReregistrationQueue.CreateRecordSet();
		
		QueueRecordset.Filter.Warehouse.Set(String.Warehouse);
		QueueRecordset.Filter.Recipient.Set(String.Recipient);
		
		QueueRecordset.Read();
		
		If QueueRecordset.Count() = 0 Then
			
			QueueRecording = QueueRecordset.Add();
			
			QueueRecording.Warehouse = String.Warehouse;
			QueueRecording.Recipient = String.Recipient;
			
			Try
				QueueRecordset.Write();
			Except
				
				MessageTemplate = NStr("vi = 'Không thể kết chuyển chứng từ: %1 do: %2';
										|ru = 'Не удалось выполнить проведение документа: %1 по причине: %2';
										|en = 'Cannot post document: %1. Reason: %2'; fa = 'Cannot post document: %1. Reason: %2';
										|it = 'Не удалось выполнить проведение документа: %1 по причине: %2';
										|pl = 'Cannot post document: %1. Reason: %2';
										|tr = '%2 nedeniyle %1 belge kaydı gerçekleştirilemedi'");
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					MessageTemplate,
					String(TransportationJob),
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
				WriteLogEvent(
					InfobaseUpdate.EventLogEvent(),
					EventLogLevel.Error,
					TransportationJob.Metadata(),
					TransportationJob,
					MessageText);
				
				Cancel = True;
				Return;
				
			EndTry;
			
			ParametersStructure = New Structure;
			ParametersStructure.Insert("Warehouse", String.Warehouse);
			ParametersStructure.Insert("Recipient", String.Recipient);
			
			WarehousesServer.StartingBackgroundReissueOfSpendingOrders(ParametersStructure);
			
		EndIf;
			
	EndDo;
	
EndProcedure

Function TextOfRegisterControlRequestGoodsForShipmentAndGoodsForDelivery() Export
	
	QueryText =
	"SELECT DISTINCT
	|	TransportationTask.Warehouse,
	|	TransportationTask.ReferenceOrder AS DocumentShipments
	|INTO OrdersForDeparture
	|FROM
	|	Document.TransportationJob.References AS TransportationTask
	|WHERE
	|	TransportationTask.Ref = &TransportationJob
	|	AND TransportationTask.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|	AND TransportationTask.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= TransportationTask.Ref.PlanTripStartTime
	|	AND TransportationTask.Warehouse.StartShipmentOnceDeliveryOrderIsCreated
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForShipmentTurnover.DocumentShipments AS DocumentShipments,
	|	GoodsForShipmentTurnover.Recipient AS Recipient,
	|	GoodsForShipmentTurnover.Warehouse AS Warehouse,
	|	GoodsForShipmentTurnover.Products AS Products,
	|	GoodsForShipmentTurnover.Characteristic AS Characteristic,
	|	GoodsForShipmentTurnover.Purpose AS Purpose,
	|	GoodsForShipmentTurnover.Series AS Series,
	|	SUM(CASE
	|		WHEN GoodsForShipmentTurnover.ToShipExpense < 0
	|			THEN -GoodsForShipmentTurnover.ToShipExpense
	|		ELSE CASE
	|				WHEN &IssueInvoicesFirst
	|					THEN GoodsForShipmentTurnover.ToShipReceipt - GoodsForShipmentTurnover.ToRegisterReceipt
	|				ELSE GoodsForShipmentTurnover.ToShipReceipt
	|			END
	|	END) AS QuantityToShip
	|INTO GoodsForIssue
	|FROM
	|	AccumulationRegister.GoodsForIssue.Turnovers(
	|			,
	|			,
	|			,
	|			(Warehouse, DocumentShipments) IN
	|				(SELECT
	|					OrdersForDeparture.Warehouse,
	|					OrdersForDeparture.DocumentShipments
	|				FROM
	|					OrdersForDeparture)) AS GoodsForShipmentTurnover
	|WHERE
	|	(CASE
	|		WHEN GoodsForShipmentTurnover.ToShipExpense < 0
	|			THEN -GoodsForShipmentTurnover.ToShipExpense
	|		ELSE CASE
	|				WHEN &IssueInvoicesFirst
	|					THEN GoodsForShipmentTurnover.ToShipReceipt - GoodsForShipmentTurnover.ToRegisterReceipt
	|				ELSE GoodsForShipmentTurnover.ToShipReceipt
	|			END
	|	END <> 0
	|				AND GoodsForShipmentTurnover.DocumentShipments.DeliveryMethod = VALUE(Enum.TransportMethods.ToCustomer)
	|			OR GoodsForShipmentTurnover.DocumentShipments.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToAddress))
	|
	|GROUP BY
	|	GoodsForShipmentTurnover.Products,
	|	GoodsForShipmentTurnover.Recipient,
	|	GoodsForShipmentTurnover.Characteristic,
	|	GoodsForShipmentTurnover.DocumentShipments,
	|	GoodsForShipmentTurnover.Series,
	|	GoodsForShipmentTurnover.Purpose,
	|	GoodsForShipmentTurnover.Warehouse
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsForShipmentTurnover.DocumentShipments,
	|	GoodsForShipmentTurnover.Recipient,
	|	GoodsForShipmentTurnover.Warehouse,
	|	GoodsForShipmentTurnover.Products,
	|	GoodsForShipmentTurnover.Characteristic,
	|	GoodsForShipmentTurnover.Purpose,
	|	GoodsForShipmentTurnover.Series,
	|	SUM(GoodsForShipmentTurnover.ToRegisterExpense)
	|FROM
	|	AccumulationRegister.GoodsForIssue.Turnovers(
	|			,
	|			,
	|			,
	|			(Warehouse, DocumentShipments) IN
	|				(SELECT
	|					OrdersForDeparture.Warehouse,
	|					OrdersForDeparture.DocumentShipments
	|				FROM
	|					OrdersForDeparture)) AS GoodsForShipmentTurnover
	|WHERE
	|	(&IssueInvoicesFirst
	|				AND GoodsForShipmentTurnover.ToRegisterExpense <> 0
	|				AND GoodsForShipmentTurnover.DocumentShipments.DeliveryMethod = VALUE(Enum.TransportMethods.ToCustomer)
	|			OR GoodsForShipmentTurnover.DocumentShipments.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToAddress))
	|
	|GROUP BY
	|	GoodsForShipmentTurnover.Purpose,
	|	GoodsForShipmentTurnover.Characteristic,
	|	GoodsForShipmentTurnover.Warehouse,
	|	GoodsForShipmentTurnover.Products,
	|	GoodsForShipmentTurnover.Series,
	|	GoodsForShipmentTurnover.DocumentShipments,
	|	GoodsForShipmentTurnover.Recipient
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssue.DocumentShipments AS DocumentShipments,
	|	GoodsForIssue.Warehouse AS Warehouse,
	|	GoodsForIssue.Recipient AS Recipient,
	|	GoodsForIssue.Products AS Products,
	|	GoodsForIssue.Characteristic AS Characteristic,
	|	GoodsForIssue.Purpose AS Purpose,
	|	GoodsForIssue.Series AS Series,
	|	GoodsForIssue.QuantityToShip,
	|	CASE
	|		WHEN GoodsToDeliver.AllGoods
	|			THEN GoodsForIssue.QuantityToShip
	|		ELSE CASE
	|				WHEN GoodsForIssue.QuantityToShip >= GoodsToDeliver.Count
	|					THEN GoodsToDeliver.Count
	|				ELSE GoodsForIssue.QuantityToShip
	|			END
	|	END AS Count
	|INTO GoodsForShipmentAndDelivery
	|FROM
	|	GoodsForIssue AS GoodsForIssue
	|		INNER JOIN InformationRegister.GoodsToDeliver AS GoodsToDeliver
	|		ON GoodsForIssue.DocumentShipments = GoodsToDeliver.ReferenceOrder
	|			AND GoodsForIssue.Warehouse = GoodsToDeliver.Warehouse
	|			AND (GoodsForIssue.Products = GoodsToDeliver.Products
	|					AND GoodsForIssue.Characteristic = GoodsToDeliver.Characteristic
	|					AND GoodsForIssue.Purpose = GoodsToDeliver.Purpose
	|					AND GoodsForIssue.Series = GoodsToDeliver.Series
	|				OR GoodsToDeliver.AllGoods)
	|			AND (GoodsToDeliver.TransportationJob = &TransportationJob)
	|			AND (GoodsToDeliver.TransportationJob.Posted)
	|			AND (GoodsToDeliver.TransportationJob.Status <> VALUE(Enum.StatusesOfTransportationJobs.BeingGenerated))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssue.DocumentShipments AS DocumentShipments,
	|	GoodsForIssue.Warehouse,
	|	GoodsForIssue.Recipient,
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	GoodsForIssue.Purpose,
	|	GoodsForIssue.Series,
	|	SUM(GoodsForIssue.ToShip) AS Count
	|INTO GoodsForIssueExpense
	|FROM
	|	AccumulationRegister.GoodsForIssue AS GoodsForIssue
	|		INNER JOIN OrdersForDeparture AS OrdersForDeparture
	|		ON GoodsForIssue.Warehouse = OrdersForDeparture.Warehouse
	|			AND GoodsForIssue.DocumentShipments = OrdersForDeparture.DocumentShipments
	|WHERE
	|	GoodsForIssue.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND GoodsForIssue.TransportationJob = &TransportationJob
	|
	|GROUP BY
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Purpose,
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	GoodsForIssue.DocumentShipments,
	|	GoodsForIssue.Recipient,
	|	GoodsForIssue.Warehouse
	|HAVING
	|	SUM(GoodsForIssue.ToShip) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssue.DocumentShipments AS DocumentShipments,
	|	GoodsForIssue.Recipient,
	|	GoodsForIssue.Warehouse,
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	GoodsForIssue.Purpose,
	|	GoodsForIssue.Series,
	|	SUM(GoodsForIssue.AssemblyInProgress + GoodsForIssue.Assembled) AS Count
	|INTO GoodsCollectedCollected_
	|FROM
	|	AccumulationRegister.GoodsForIssue AS GoodsForIssue
	|		INNER JOIN OrdersForDeparture AS OrdersForDeparture
	|		ON GoodsForIssue.Warehouse = OrdersForDeparture.Warehouse
	|			AND GoodsForIssue.DocumentShipments = OrdersForDeparture.DocumentShipments
	|WHERE
	|	GoodsForIssue.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND GoodsForIssue.TransportationJob = &TransportationJob
	|
	|GROUP BY
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Purpose,
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	GoodsForIssue.DocumentShipments,
	|	GoodsForIssue.Recipient,
	|	GoodsForIssue.Warehouse
	|HAVING
	|	SUM(GoodsForIssue.AssemblyInProgress + GoodsForIssue.Assembled) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssue.DocumentShipments AS DocumentShipments,
	|	GoodsForIssue.Recipient,
	|	GoodsForIssue.Warehouse,
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	GoodsForIssue.Purpose,
	|	GoodsForIssue.Series,
	|	SUM(GoodsForIssue.ForAssembly) AS Count
	|INTO ProductsReadyForAssembly
	|FROM
	|	AccumulationRegister.GoodsForIssue AS GoodsForIssue
	|		INNER JOIN OrdersForDeparture AS OrdersForDeparture
	|		ON GoodsForIssue.Warehouse = OrdersForDeparture.Warehouse
	|			AND GoodsForIssue.DocumentShipments = OrdersForDeparture.DocumentShipments
	|WHERE
	|	GoodsForIssue.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND GoodsForIssue.TransportationJob = &TransportationJob
	|
	|GROUP BY
	|	GoodsForIssue.Series,
	|	GoodsForIssue.Purpose,
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	GoodsForIssue.DocumentShipments,
	|	GoodsForIssue.Recipient,
	|	GoodsForIssue.Warehouse
	|HAVING
	|	 SUM(GoodsForIssue.ForAssembly) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	Return QueryText
	
EndFunction

// Parameters:
//  Object - DocumentObject.TransportationJob -
//  	   - FormDataStructure: See Document.TransportationJob.Form.DocumentForm.Object
// 
// Returns:
//  String
//
Function FillInFlightTimePlanFact(Object) Export
	
	MaximumSoftwareTime = GoodsDelivery.MaximumSoftwareTime(Object);
	
	MessageTexts_ = New Array; // Array of String
	
	If Object.Status <> Enums.StatusesOfTransportationJobs.BeingGenerated
		And Not ValueIsFilled(Object.PlanTripStartTime) Then
		
		Object.PlanTripStartTime = CurrentSessionDate();
		MessageTexts_.Add(NStr("vi = 'kế hoạch. thời gian bắt đầu chuyến hàng';
								|ru = 'план. время начала рейса';
								|en = 'plan. trip start time'; fa = 'plan. trip start time';
								|it = 'orario previsto di inizio del viaggio';
								|pl = 'plan. czas początku rejsu';
								|tr = 'Planlanan seyahat başlangıç zamanı'"));
		
	EndIf;
	
	If Object.Status <> Enums.StatusesOfTransportationJobs.BeingGenerated
		And Object.Status <> Enums.StatusesOfTransportationJobs.ToLoad
		And Not ValueIsFilled(Object.PlanTripEndTime) Then
		
		Object.PlanTripEndTime = Max(MaximumSoftwareTime,Object.PlanTripStartTime);
		MessageTexts_.Add(NStr("vi = 'kế hoạch. thời gian kết thúc chuyến hàng';
								|ru = 'план. время окончания рейса';
								|en = 'plan. trip end time'; fa = 'plan. trip end time';
								|it = 'orario previsto del termine di viaggio';
								|pl = 'plan. czas zakończenia rejsu';
								|tr = 'Planlanan seyahat bitiş zamanı'"));
		
	EndIf;
	
	If (Object.Status = Enums.StatusesOfTransportationJobs.Sent
			Or Object.Status = Enums.StatusesOfTransportationJobs.Closed)
		And Not ValueIsFilled(Object.ActualTripStartTime) Then
		
		Object.ActualTripStartTime = CurrentSessionDate();
		MessageTexts_.Add(NStr("vi = 'thời gian thực tế bắt đầu chuyến hàng';
								|ru = 'факт. время начала рейса';
								|en = 'actual trip start time'; fa = 'actual trip start time';
								|it = 'orario effettivo dell''inizio di viaggio';
								|pl = 'fakt. czas początku rejsu';
								|tr = 'Gerçekleşen seyahat başlangıç zamanı'"));
		
	EndIf;
	
	If Object.Status = Enums.StatusesOfTransportationJobs.Closed
		And Not ValueIsFilled(Object.ActualTripEndTime) Then
		
		Object.ActualTripEndTime = CurrentSessionDate();
		MessageTexts_.Add(NStr("vi = 'thời gian thực tế kết thúc chuyến hàng';
								|ru = 'факт. время окончания рейса';
								|en = 'actual trip end time'; fa = 'actual trip end time';
								|it = 'orario effettivo del termine di viaggio';
								|pl = 'fakt. czas zakończenia rejsu';
								|tr = 'Gerçekleşen seyahat bitiş zamanı'"));
		
	EndIf;
	
	If ValueIsFilled(Object.PlanTripEndTime) Then
		Object.PlanTripEndTime = Max(Object.PlanTripStartTime, Object.PlanTripEndTime);
	EndIf;
	If ValueIsFilled(Object.ActualTripEndTime) Then
		Object.ActualTripEndTime = Max(Object.ActualTripStartTime, Object.ActualTripEndTime);
	EndIf;
	
	If MessageTexts_.Count() > 0 Then
		TimeMessageText = NStr("vi = 'Đã điền';
								|ru = 'Заполнено';
								|en = 'Filled'; fa = 'پرشده';
								|it = 'Заполнено';
								|pl = 'Filled';
								|tr = 'Dolduruldu'") + " %Time0, %Time1, %Time2, %Time3.";
		For Cnt = 0 To MessageTexts_.UBound() Do
			TimeMessageText = StrReplace(TimeMessageText, "%Time"+Cnt, MessageTexts_[Cnt]);
		EndDo;
		For Cnt = 1 To 3 Do
			TimeMessageText = StrReplace(TimeMessageText, ", %Time"+Cnt, "");
		EndDo;
	EndIf;
	
	Return TimeMessageText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
