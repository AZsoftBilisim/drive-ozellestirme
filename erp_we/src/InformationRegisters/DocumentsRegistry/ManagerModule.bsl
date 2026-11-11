#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	Parameters.IndependentRegisters.Add(Metadata.InformationRegisters.DocumentsRegistry);
	
	Return Parameters;
	
EndFunction

// The procedure of formation of movements on the slave registers of the international registration.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
EndProcedure

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
//	Document - DocumentRef - link to the document
//	TempTablesManager - TempTablesManager - Manager temporary tables in the document
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure WriteData(TablesForRegisteredRecords, Document, TempTablesManager, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	TableDocumentRegistry = Undefined;
	If Not TablesForRegisteredRecords.Property("Table" + "DocumentsRegistry", TableDocumentRegistry) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Set = InformationRegisters.DocumentsRegistry.CreateRecordSet();
	
	If TempTablesManager <> Undefined Then
		Set.AdditionalProperties.Insert("TempTablesManager", TempTablesManager);
	EndIf;
	
	Set.Filter.Ref.Set(Document);
	Set.UploadWithProcessing(TableDocumentRegistry);
	Set.Write();
	
	InfobaseUpdateTM.MarkInteractiveProcessing(Set);
	
	SetPrivilegedMode(False);
	
EndProcedure

// Writes data to the register based on the passed record separator.
//
// Parameters:
//  TablesForRegisteredRecords		 - Structure - contains a structure
//  	that has the key of the table of Registrdocuments (table of Values) by the key of the table of Movements.
//  RecordSeparator		 - String - dimension to be recorded for
//  ReplaceRecords			 - Boolean - determines the mode of replacement of existing records of the separator. True - existing
//		records will be deleted before recording. False-records will be added to existing records in the information database.
//
Procedure WriteSeparatorData(TablesForRegisteredRecords, RecordSeparator, ReplaceRecords = True) Export
	
	SetPrivilegedMode(True);
	
	Set = InformationRegisters.DocumentsRegistry.CreateRecordSet();
	Set.Filter.RecordSeparator.Set(RecordSeparator);
	Set.UploadWithProcessing(TablesForRegisteredRecords["Table" + "DocumentsRegistry"]);
	Set.Write(ReplaceRecords);
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

// Returns a flag indicating whether the received object's data is reflected in the information registry or not.
//
// Parameters:
//	ObjectToCheck - DocumentObject, DocumentRef, FormDataStructure, MetadataObject - 
//
// Returns:
//	Boolean - True if the data of the received object is reflected in the information register.
//
Function ObjectIsIncludedInRegistryData(ObjectToCheck) Export
	
	ValueType = TypeOf(ObjectToCheck);
	If ValueType = Type("FormDataStructure") Then
		If Not ObjectToCheck.Property("Ref") Then
			Return False;
		EndIf;
		RefType = TypeOf(ObjectToCheck.Ref);
	Else	
		If ValueType = Type("MetadataObject") Then
			ValueMetadata = ObjectToCheck; // MetadataObjectDocument
		Else
			ValueMetadata = Metadata.FindByType(ValueType); // MetadataObjectDocument
			
			If ValueMetadata = Undefined Then
				Return False;
			EndIf;
		EndIf;
		
		If Not Common.IsDocument(ValueMetadata) Then
			Return False;
		EndIf;

		RefType = TypeOf(ValueMetadata.StandardAttributes.Ref.Type.AdjustValue());
	EndIf;

	Return Metadata.InformationRegisters.DocumentsRegistry.Dimensions.Ref.Type.ContainsType(RefType);
	
EndFunction

// Initializes and writes data from documents that have received metadata objects to the data register.
//
// Parameters:
//	MetadataObjects - Map - metadata objects:
//		* Key		- MetadataObjectDocument	- the object metadata of the document.
//		* Value	- Undefined				- empty value.
//
Procedure ReflectDocumentDataInRegistry(MetadataObjects) Export
	
	ObjectsNames		= New Array;
	DocumentLinks_	= New Array;
	
	For Each DataElement In MetadataObjects Do
		DataObject		= DataElement.Key;
		FullObjectName	= DataObject.FullName();
		
		ObjectsNames.Add(FullObjectName);
	EndDo;
	
	UnusedFields = New Array;
	UnusedFields.Add("More");
	UnusedFields.Add("SourceDocumentNumber");
	UnusedFields.Add("RecordID");
	
	For Each FullObjectName In ObjectsNames Do
		
		DocumentName = StrSplit(FullObjectName, ".")[1];
		ResultOfRequestAdaptation = Documents[DocumentName].AdaptedCaseSensitiveQueryText("DocumentsRegistry");
		Recorders = InfobaseUpdateTM.IndependentRegisterDataForRecheck(
							ResultOfRequestAdaptation,
							"InformationRegister.DocumentsRegistry",
							FullObjectName,
							UnusedFields);
		
		CommonClientServer.SupplementArray(DocumentLinks_, Recorders.UnloadColumn("Ref"));
		
	EndDo;
	
	For Each Ref In DocumentLinks_ Do
		DataTables = DocumentsPosting.DocumentDataForPosting(Ref, "DocumentsRegistry");
		InformationRegisters.DocumentsRegistry.WriteData(DataTables, Ref, Undefined, False);
	EndDo;
	
EndProcedure

// Returns a collection of types that are included in the 'Reference' dimension.
//
// Returns:
//	Array of Type - a collection of types that are included in the 'Reference' dimension.
//
Function TypesOfRegistryDocuments() Export
	
	TypesReference = Metadata.InformationRegisters.DocumentsRegistry.Dimensions.Ref.Type.Types();
	
	TypesToExclude = New Array;
	TypesToExclude.Add(Type("DocumentRef.OBEntry"));
	
	If TypesToExclude.Count() Then
		DocumentTypes = CommonClientServer.ArraysDifference(TypesReference, TypesToExclude);
	Else
		DocumentTypes = TypesReference;
	EndIf;
	
	Return DocumentTypes;
	
EndFunction

// Returns the key of the registry entry for the transmitted document link.
//
// Parameters:
//	Ref - DocumentRef - link to the document for which you need to generate the registry entry key.
//
// Returns:
//	InformationRegisterRecordKey.DocumentsRegistry - if the key is not found for the link, it is returned Undefined.
//
Function DocumentRecordingKey(Ref) Export
	
	SelectionFields1 = New Array;
	RegisterName = Metadata.InformationRegisters.DocumentsRegistry.Name;
	For Each Dimension In Metadata.InformationRegisters.DocumentsRegistry.Dimensions Do
		SelectionFields1.Add(Chars.Tab + RegisterName + "." + Dimension.Name);
	EndDo;
	
	Query = New Query;
	QueryText = 
	"SELECT
	|&SelectionFields1
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.Ref = &Ref
	|	AND NOT DocumentsRegistry.AdditionalRecord";
	QueryText = StrReplace(QueryText, "&SelectionFields1", StrConcat(SelectionFields1,"," + Chars.LF));
	
	Query.Text = QueryText;
	Query.SetParameter("Ref", Ref);
	ResultOfOvergrowth = Query.Execute();
	Selection = ResultOfOvergrowth.Select();
	RecordKey = Undefined;
	If Selection.Next() Then
		KeyData = New Structure;
		For Each Column In ResultOfOvergrowth.Columns Do
			KeyData.Insert(Column.Name, Selection[Column.Name]);
		EndDo;
		RecordKey = InformationRegisters.DocumentsRegistry.CreateRecordKey(KeyData);
	EndIf;
	
	Return RecordKey;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE
	|	ObjectReadingAllowed(Ref)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ObjectUpdateAllowed(Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.DocumentsRegistry.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.47";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("a81d07e9-0d8b-4816-9c92-2fdc0f7aea6c");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.DocumentsRegistry.RegisterDataForProcessing";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	
	HandlerDetails = New Array;
	HandlerDetails.Add(
		NStr("vi = 'Cập nhật các bản ghi của biểu ghi thông tin ""Danh sách chứng từ"".';
			|ru = 'Обновление записей регистра сведений ""Реестр документов"".';
			|en = 'Update ""Document registry"" information register records.'; fa = 'Update ""Document registry"" information register records.';
			|it = 'Обновление записей регистра сведений ""Реестр документов"".';
			|pl = 'Update ""Document registry"" information register records.';
			|tr = 'Bilgi kaydı “Belge kaydı” kayıtlarının güncellenmesi.'"));
	HandlerDetails.Add(
		NStr("vi = ' - điền ""Nơi lưu"" trong danh sách chứng từ theo chứng từ ""Công đoạn sản xuất"".';
			|ru = ' - заполнение ""Места хранения"" в реестре документов по документам ""Этап производства"".';
			|en = ' - fill ""Storage locations"" in the document registry for the ""Production stage"" document.'; fa = ' - fill ""Storage locations"" in the document registry for the ""Production stage"" document.';
			|it = ' - заполнение ""Места хранения"" в реестре документов по документам ""Этап производства"".';
			|pl = ' - fill ""Storage locations"" in the document registry for the ""Production stage"" document.';
			|tr = ' - “Üretim aşaması” belgeleri için belge kaydında “Depolama yeri ”nin doldurulması.'"));
	HandlerDetails.Add(
		NStr("vi = ' - cập nhật các bản ghi theo chứng từ ""Biên bản công việc nội bộ đã thực hiện"".';
			|ru = ' - обновление записей по документам ""Акт выполненных внутренних работ"".';
			|en = ' - update ""Internal work acceptance"" document records.'; fa = ' - update ""Internal work acceptance"" document records.';
			|it = ' - update ""Internal work acceptance"" document records.';
			|pl = ' - update ""Internal work acceptance"" document records.';
			|tr = ' - ""Tamamlanan dahili iş tutanağı"" belgeleri için kayıtların güncellenmesi.'"));
	
	HandlerDetails.Add(
		NStr("vi = ' - cập nhật các bản ghi theo chứng từ ""Sản lượng của nhân viên"".';
			|ru = ' - обновление записей по документам ""Выработка сотрудников"".';
			|en = ' - update ""Timesheets charge"" document records.'; fa = ' - update ""Timesheets charge"" document records.';
			|it = ' - update ""Timesheets charge"" document records.';
			|pl = ' - update ""Timesheets charge"" document records.';
			|tr = ' - ""Zaman çizelgesi bazlı ücretlendirme"" belgelerine ait kayıtların güncellenmesi.'"));
	
	HandlerDetails.Add(
		NStr("vi = ' - cập nhật các bản ghi theo chứng từ ""Biến động sản phẩm và nguyên vật liệu"".';
			|ru = ' - обновление записей по документам ""Движения продукции и материалов"".';
			|en = ' - update ""Movements of products and materials"" document records.'; fa = ' - update ""Movements of products and materials"" document records.';
			|it = ' - обновление записей по документам ""Движения продукции и материалов"".';
			|pl = ' - update ""Movements of products and materials"" document records.';
			|tr = ' - “Ürün ve malzeme hareketleri” belgelerindeki kayıtların güncellenmesi.'"));
	
	HandlerDetails.Add(
		NStr("vi = ' - cập nhật các bản ghi theo chứng từ ""Sản xuất không có đơn hàng"".';
			|ru = ' - обновление записей по документам ""Производство без заказа"".';
			|en = ' - update ""Backflush production"" document records.'; fa = ' - update ""Backflush production"" document records.';
			|it = ' - обновление записей по документам ""Производство без заказа"".';
			|pl = ' - update ""Backflush production"" document records.';
			|tr = ' - ""Geriye dönük üretim"" belgeleri için kayıtları güncelleme.'"));
	
	HandlerDetails.Add(
		NStr("vi = ' - cập nhật các bản ghi theo chứng từ ""Đơn đặt hàng vật tư trong sản xuất"".';
			|ru = ' - обновление записей по документам ""Заказ материалов в производство"".';
			|en = ' - update ""Material order for shop floor stockroom"" document records.'; fa = ' - update ""Material order for shop floor stockroom"" document records.';
			|it = ' - update ""Material order for shop floor stockroom"" document records.';
			|pl = ' - update ""Material order for shop floor stockroom"" document records.';
			|tr = ' - ""Üretim için malzeme siparişi"" belgelerine ait kayıtların güncellenmesi.'"));
	HandlerDetails.Add(NStr("vi = ' - cập nhật bản ghi của biểu ghi theo chứng từ ""Chi tiền từ tài khoản ngân hàng"".';
							|ru = ' - обновление записей регистра по документу ""Списание безналичных ДС"".';
							|en = ' - Update register records of the ""Outgoing payments — Bank account"" document.'; fa = ' - Update register records of the ""Outgoing payments — Bank account"" document.';
							|it = ' - Update register records of the ""Outgoing payments — Bank account"" document.';
							|pl = ' - Update register records of the ""Outgoing payments — Bank account"" document.';
							|tr = ' - ""Giden ödeme — banka hesabı"" belgesi için kayıt girişlerinin güncellenmesi.'"));
	HandlerDetails.Add(NStr("vi = ' - cập nhật các bản ghi của biểu ghi theo chứng từ ""Hóa đơn GTGT đầu vào (tạm ứng)"".';
							|ru = ' - обновление записей регистра по документу ""Счет-фактура полученный (аванс)"".';
							|en = ' - update register records of the ""Received tax invoice (advance)"" document.'; fa = ' - update register records of the ""Received tax invoice (advance)"" document.';
							|it = ' - update register records of the ""Received tax invoice (advance)"" document.';
							|pl = ' - update register records of the ""Received tax invoice (advance)"" document.';
							|tr = ' - ""Alınan vergi faturaları (avans)"" belgesine ait kayıtların güncellenmesi.'"));
	HandlerDetails.Add(NStr("vi = ' - cập nhật các bản ghi của biểu ghi theo chứng từ ""Phiếu chi"".';
							|ru = ' - обновление записей регистра по документу ""Расходный кассовый ордер"".';
							|en = ' - Update register records of the ""Outgoing payment — Cash account"" document.'; fa = ' - Update register records of the ""Outgoing payment — Cash account"" document.';
							|it = ' - Update register records of the ""Outgoing payment — Cash account"" document.';
							|pl = ' - Update register records of the ""Outgoing payment — Cash account"" document.';
							|tr = ' - ""Giden ödeme - kasa hesabı"" belgesine ait kayıtların güncellenmesi.'"));
	
	HandlerDetails.Add(
		NStr("vi = ' - cập nhật các bản ghi theo chứng từ ""Đơn hàng điều chuyển nội bộ"".';
			|ru = ' - обновление записей по документам ""Заказ на перемещение"".';
			|en = ' - update ""Transfer order"" document records.'; fa = ' - update ""Transfer order"" document records.';
			|it = ' - update ""Transfer order"" document records.';
			|pl = ' - update ""Transfer order"" document records.';
			|tr = ' - ""Transfer emri"" belgelerine ait kayıtların güncellenmesi.'"));
	
	HandlerDetails.Add(
		NStr("ru = ' - обновление записей по документам ""Списание товаров, отгруженных клиенту"".';
			|vi = ' - update ""Write-off of goods shipped to customer"" document records.';
			|en = ' - update ""Write-off of goods shipped to customer"" document records.'; fa = ' - update ""Write-off of goods shipped to customer"" document records.';
			|it = ' - update ""Write-off of goods shipped to customer"" document records.';
			|pl = ' - update ""Write-off of goods shipped to customer"" document records.';
			|tr = ' - ""Müşteriye sevk edilen ürünlerin gider yazılması"" belgelerine ait kayıtların güncellenmesi.'"));
	
	Handler.Comment = StrConcat(HandlerDetails, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.InternalAcceptanceCertificate.FullName());
	ItemsToRead.Add(Metadata.Documents.WorkOutput.FullName());
	ItemsToRead.Add(Metadata.Documents.MovementOfProductsAndMaterials.FullName());
	ItemsToRead.Add(Metadata.Documents.BackflushProduction.FullName());
	ItemsToRead.Add(Metadata.Documents.OrderOfMaterialsForProduction.FullName());
	ItemsToRead.Add(Metadata.Documents.ProductionStage2_2.FullName());
	ItemsToRead.Add(Metadata.Documents.TransferOrder.FullName());
	ItemsToRead.Add(Metadata.Documents.BankAccountIssue.FullName());
	ItemsToRead.Add(Metadata.Documents.ReceivedTaxInvoicePrepayment.FullName());
	ItemsToRead.Add(Metadata.Documents.CashVoucher.FullName());
	ItemsToRead.Add(Metadata.Documents.WriteOffOfShippedGoods.FullName());
	ItemsToRead.Add(Metadata.InformationRegisters.DocumentsRegistry.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.DocumentsRegistry.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.InformationRegisters.DocumentsRegistry.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Registers documents for processing for modification.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataForProcessing(Parameters) Export 
	
	FullRegisterName  = "InformationRegister.DocumentsRegistry";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("IBDocumentDate DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Ref");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	SelectionParameters.NameOfTheDimensionToSelect = "Ref";
	
	FullNamesOfObjects = New Array;
	FullNamesOfObjects.Add("Document.InternalAcceptanceCertificate");
	FullNamesOfObjects.Add("Document.WorkOutput");
	FullNamesOfObjects.Add("Document.MovementOfProductsAndMaterials");
	FullNamesOfObjects.Add("Document.BackflushProduction");
	FullNamesOfObjects.Add("Document.OrderOfMaterialsForProduction");
	FullNamesOfObjects.Add("Document.ProductionStage2_2");
	FullNamesOfObjects.Add("Document.TransferOrder");
	FullNamesOfObjects.Add("Document.BankAccountIssue");
	FullNamesOfObjects.Add("Document.ReceivedTaxInvoicePrepayment");
	FullNamesOfObjects.Add("Document.CashVoucher");
	FullNamesOfObjects.Add("Document.WriteOffOfShippedGoods");

	SelectionParameters.FullNamesOfObjects  = StrConcat(FullNamesOfObjects, ",");
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", FullRegisterName);
	
	#Region InternalAcceptanceCertificate
	
	UnusedFields = New Array;
	UnusedFields.Add("SourceDocumentNumber");
	UnusedFields.Add("RecordID");
	
	Recorders =
		InfobaseUpdateTM.IndependentRegisterDataForRecheck(
			Documents.InternalAcceptanceCertificate.AdaptedCaseSensitiveQueryText("DocumentsRegistry"),
			FullRegisterName,
			"Document.InternalAcceptanceCertificate",
			UnusedFields);
	
	InfobaseUpdate.MarkForProcessing(Parameters, Recorders, AdditionalParameters);
	
	#EndRegion
	
	#Region WorkOutput
	
	UnusedFields = New Array;
	UnusedFields.Add("SourceDocumentNumber");
	
	Recorders =
		InfobaseUpdateTM.IndependentRegisterDataForRecheck(
			Documents.WorkOutput.AdaptedCaseSensitiveQueryText("DocumentsRegistry"),
			FullRegisterName,
			"Document.WorkOutput",
			UnusedFields);
	
	InfobaseUpdate.MarkForProcessing(Parameters, Recorders, AdditionalParameters);
	
	#EndRegion
	
	#Region MovementOfProductsAndMaterials
	
	UnusedFields = New Array;
	UnusedFields.Add("SourceDocumentNumber");
	UnusedFields.Add("More");
	UnusedFields.Add("RecordID");
	
	Recorders =
		InfobaseUpdateTM.IndependentRegisterDataForRecheck(
			Documents.MovementOfProductsAndMaterials.AdaptedCaseSensitiveQueryText("DocumentsRegistry"),
			FullRegisterName,
			"Document.MovementOfProductsAndMaterials",
			UnusedFields);
	
	InfobaseUpdate.MarkForProcessing(Parameters, Recorders, AdditionalParameters);
	
	#EndRegion
	
	#Region BackflushProduction
	
	UnusedFields = New Array;
	UnusedFields.Add("SourceDocumentNumber");
	UnusedFields.Add("RecordID");
	
	Recorders =
		InfobaseUpdateTM.IndependentRegisterDataForRecheck(
			Documents.BackflushProduction.AdaptedCaseSensitiveQueryText("DocumentsRegistry"),
			FullRegisterName,
			"Document.BackflushProduction",
			UnusedFields);
	
	InfobaseUpdate.MarkForProcessing(Parameters, Recorders, AdditionalParameters);
	
	#EndRegion
	
	#Region OrderOfMaterialsForProduction
	
	UnusedFields = New Array;
	UnusedFields.Add("RecordID");
	UnusedFields.Add("SourceDocumentName");
	
	Recorders =
		InfobaseUpdateTM.IndependentRegisterDataForRecheck(
			Documents.OrderOfMaterialsForProduction.AdaptedCaseSensitiveQueryText("DocumentsRegistry"),
			FullRegisterName,
			"Document.OrderOfMaterialsForProduction",
			UnusedFields);
	
	InfobaseUpdate.MarkForProcessing(Parameters, Recorders, AdditionalParameters);
	
	#EndRegion
	
	#Region ProductionStage2_2
	
	UnusedFields = New Array;
	UnusedFields.Add("RecordID");
	
	Recorders =
		InfobaseUpdateTM.IndependentRegisterDataForRecheck(
			Documents.ProductionStage2_2.AdaptedCaseSensitiveQueryText("DocumentsRegistry"),
			FullRegisterName,
			"Document.ProductionStage2_2",
			UnusedFields);
	
	InfobaseUpdate.MarkForProcessing(Parameters, Recorders, AdditionalParameters);
	
	#EndRegion
	
	#Region BankAccountIssue
	
	UnusedFields = New Array;
	UnusedFields.Add("RecordID");
	
	Recorders =
		InfobaseUpdateTM.IndependentRegisterDataForRecheck(
			Documents.BankAccountIssue.AdaptedCaseSensitiveQueryText("DocumentsRegistry"),
			FullRegisterName,
			"Document.BankAccountIssue",
			UnusedFields);
	
	InfobaseUpdate.MarkForProcessing(Parameters, Recorders, AdditionalParameters);
	
	#EndRegion

	#Region ReceivedTaxInvoicePrepayment
	
	UnusedFields = New Array;
	UnusedFields.Add("RecordID");
	
	Recorders =
		InfobaseUpdateTM.IndependentRegisterDataForRecheck(
			Documents.ReceivedTaxInvoicePrepayment.AdaptedCaseSensitiveQueryText("DocumentsRegistry"),
			FullRegisterName,
			"Document.ReceivedTaxInvoicePrepayment",
			UnusedFields);
	
	InfobaseUpdate.MarkForProcessing(Parameters, Recorders, AdditionalParameters);
	
	#EndRegion
	
	#Region TransferOrder
	
	UnusedFields = New Array;
	UnusedFields.Add("RecordID");
	UnusedFields.Add("SourceDocumentName");
	
	Recorders =
		InfobaseUpdateTM.IndependentRegisterDataForRecheck(
			Documents.TransferOrder.AdaptedCaseSensitiveQueryText("DocumentsRegistry"),
			FullRegisterName,
			"Document.TransferOrder",
			UnusedFields);
	
	InfobaseUpdate.MarkForProcessing(Parameters, Recorders, AdditionalParameters);
	
	#EndRegion

	#Region CashVoucher
	
	UnusedFields = New Array;
	UnusedFields.Add("RecordID");
	
	Recorders =
		InfobaseUpdateTM.IndependentRegisterDataForRecheck(
			Documents.CashVoucher.AdaptedCaseSensitiveQueryText("DocumentsRegistry"),
			FullRegisterName,
			"Document.CashVoucher",

			UnusedFields);
	
	InfobaseUpdate.MarkForProcessing(Parameters, Recorders, AdditionalParameters);
	
	#EndRegion
	
	#Region WriteOffOfShippedGoods
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	WriteOff.Ref AS Ref
	|FROM
	|	Document.WriteOffOfShippedGoods AS WriteOff
	|	INNER JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON WriteOff.Ref = DocumentsRegistry.Ref
	|WHERE
	|	WriteOff.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods)
	|	AND CAST(DocumentsRegistry.StorageLocation.Key AS Catalog.Warehouses) IS NULL
	|";
	
	Recorders = Query.Execute().Unload();
	InfobaseUpdate.MarkForProcessing(Parameters, Recorders, AdditionalParameters);
	
	#EndRegion
	
EndProcedure

// An update handler.
// 
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	AllKeysProcessed = True;
	
	MetadataObjects = Catalogs.DocumentRegistryKeys.MetadataObjectsEncodedInRegistryKeys();
	MetadataObjects.Insert(Metadata.Catalogs.DocumentRegistryKeys);
	
	For Each MetadataObject In MetadataObjects Do
		LockedAttributesAvailable = InfobaseUpdate.HasDataLockedByPreviousQueues(Parameters.Queue,
			MetadataObject.Key.FullName());
		If LockedAttributesAvailable Then
			AllKeysProcessed = False;
			Break;
		EndIf;
	EndDo;

	If Not AllKeysProcessed Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf;
	
	AdditionalParameters = InfobaseUpdateTM.AdditionalOptionsForOverwritingRegisteredRecordsFromQueue();
	AdditionalParameters.IsIndependentInformationRegister = True;
	AdditionalParameters.NameOfTheDimensionToSelect = "Ref";
	AdditionalParameters.WriteInSingleTransaction = False;
	AdditionalParameters.NeedAdditionalRecordProcessing = True;
	AdditionalParameters.UpdatedData = Parameters.UpdatedData;
	
	AllDone_ =
		InfobaseUpdateTM.OverwriteRegisteredRecordsFromQueue(
			Undefined,
			"InformationRegister.DocumentsRegistry",
			Parameters.Queue,
			AdditionalParameters);
	
	Parameters.ProcessingCompleted = AllDone_;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
