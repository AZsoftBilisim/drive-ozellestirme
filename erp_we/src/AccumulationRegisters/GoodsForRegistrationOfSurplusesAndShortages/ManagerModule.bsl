#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Warehouse)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.GoodsForRegistrationOfSurplusesAndShortages.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.23.13";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("ccd3d9d8-5118-4b88-8a68-185aa0023b69");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.GoodsForRegistrationOfSurplusesAndShortages.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.Comment = NStr("vi = 'Đang cập nhật bản ghi kết chuyển của chứng từ trong cơ sở thông tin theo biểu ghi tích lũy ""Hàng cần lập chứng từ ghi nhận hàng thừa và hàng thiếu"".
	|Trước khi hoàn thành hàm sự kiện, không nên làm việc với chứng từ, bởi vì thông tin trong biểu ghi sẽ không chính xác.';
	|ru = 'Обновляет движения документов информационной базы по регистру накопления ""Товары к оформлению излишков и недостач"".
	|До завершения обработчика работа с документами не рекомендуется, т.к. информация в регистре некорректна.';
	|en = 'Updates register records of infobase documents in the ""Goods for registration of surpluses and shortages"" accumulation register.
	|Until the handler is finished, we do not recommend that you work with the documents, as information in the register is incorrect.'; fa = 'Updates register records of infobase documents in the ""Goods for registration of surpluses and shortages"" accumulation register.
	|Until the handler is finished, we do not recommend that you work with the documents, as information in the register is incorrect.';
	|it = 'Updates register records of infobase documents in the ""Goods for registration of surpluses and shortages"" accumulation register.
	|Until the handler is finished, we do not recommend that you work with the documents, as information in the register is incorrect.';
	|pl = 'Updates register records of infobase documents in the ""Goods for registration of surpluses and shortages"" accumulation register.
	|Until the handler is finished, we do not recommend that you work with the documents, as information in the register is incorrect.';
	|tr = '""Fazlalıkların ve eksikliklerin düzenlenmesi için ürünler"" birikim kaydındaki infobase belgelerinin hareketlerini günceller.
	|İşleyici tamamlanana kadar belgelerle çalışılması önerilmemektedir çünkü kayıttaki bilgiler hatalıdır.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.DiscrepancyReportFollowingShipment.FullName());
	ItemsToRead.Add(Metadata.Documents.DiscrepancyReportFollowingTransfer.FullName());
	ItemsToRead.Add(Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName());
	ItemsToRead.Add(Metadata.Documents.PurchaseAdjustment.FullName());
	ItemsToRead.Add(Metadata.Documents.SaleAdjustment.FullName());
	
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.GoodsForRegistrationOfSurplusesAndShortages.FullName());
	
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.AccumulationRegisters.GoodsForRegistrationOfSurplusesAndShortages.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Registers documents for processing for modification.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	DocumentsList	= DocumentsToUpdate();
	FullRegisterName	= "AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = StrConcat(DocumentsList, ",");
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	RegisterName = "GoodsForRegistrationOfSurplusesAndShortages";
	
	AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	AddlParameters.GetQueryTexts = True;
	
	Recorders = New Array;
	
	For Each FullDocumentName In DocumentsList Do
		DocumentName	= StrSplit(FullDocumentName, ".")[1];
		QueryTexts	= Documents[DocumentName].DocumentDataForPosting(Undefined, RegisterName, AddlParameters);
		
		CommonTemporaryTables = Undefined;
		If FullDocumentName = "Document.DiscrepancyReportFollowingReceipt" Then
			CommonTemporaryTables = New Array();
			Documents.DiscrepancyReportFollowingReceipt.QueryTextDocumentData(CommonTemporaryTables);
			For Each Item In QueryTexts Do
				// The peculiarity of the formation of query texts is in the mechanics of the warehouse.
				// Further, the text is not perceived by the mechanics of rechecking.
				Item.Value = StrReplace(Item.Value, "(Goods.Warehouse)", "Goods.Warehouse");
				Item.Value = StrReplace(Item.Value, "(Goods.Purpose)", "Goods.Purpose");
			EndDo;
		EndIf;
			
		RecordersByDocumentType = DocumentsPosting.CallLoggers(
			QueryTexts,
			FullRegisterName,
			FullDocumentName,
			CommonTemporaryTables);
		
		CommonClientServer.SupplementArray(Recorders, RecordersByDocumentType);
	EndDo;
	
	InfobaseUpdate.MarkRecordersForProcessing(Parameters, Recorders, FullRegisterName);
	
EndProcedure

// An update handler.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	DocumentsList	= DocumentsToUpdate();
	FullRegisterName	= "AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages";
	
	AdditionalParameters = InfobaseUpdateTM.AdditionalOptionsForOverwritingRegisteredRecordsFromQueue();
	AdditionalParameters.UpdatedData = Parameters.UpdatedData;
	
	ProcessingCompleted = InfobaseUpdateTM.OverwriteRegisteredRecordsFromQueue(DocumentsList,
																						FullRegisterName,
																						Parameters.Queue,
																						AdditionalParameters);
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region InfobaseUpdate

Function DocumentsToUpdate()
	
	DocumentsList = New Array;
	DocumentsList.Add("Document.DiscrepancyReportFollowingShipment");
	DocumentsList.Add("Document.DiscrepancyReportFollowingTransfer");
	DocumentsList.Add("Document.DiscrepancyReportFollowingReceipt");
	DocumentsList.Add("Document.PurchaseAdjustment");
	DocumentsList.Add("Document.SaleAdjustment");
	
	Return DocumentsList;
	
EndFunction

#EndRegion

#EndRegion

#EndIf