#If Not MobileStandaloneServer Then

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	StandardProcessing = False;
	
	Fields.Add("Description");
	Fields.Add("Contract");
	Fields.Add("BusinessOperation");
	Fields.Add("ReceiptDocumentNumber");
	Fields.Add("DateOfReceiptDocument");
	Fields.Add("Lot");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	Presentation = Data.Description;
	
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		
		#If Client Then
			IsMainLanguage = TMCommonUseClientCached.IsMainLanguage();
		#Else
			IsMainLanguage = TMCommonUseCached.IsMainLanguage();
		#EndIf
		
		If Not IsMainLanguage Then
			Presentation = QualityControlClientServer.PresentationOfControlledLotReference(Data, CurrentLanguage().LanguageCode);
		EndIf;
		
	#EndIf
	
EndProcedure

#EndRegion

#EndIf

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.ControlledLots.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.27.26";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("4a0d0088-7303-40bd-94cc-d6954c6af9a4");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.ControlledLots.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Lô hàng được kiểm soát"":';
								|ru = 'Обновление справочника ""Контролируемые партии"":';
								|en = 'Update the ""Controlled lots"" catalog:'; fa = 'Update the ""Controlled lots"" catalog:';
								|it = 'Update the ""Controlled lots"" catalog:';
								|pl = 'Update the ""Controlled lots"" catalog:';
								|tr = '""Kontrol edilen lotlar"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = 'Điền giá trị cho mục tin mới ""Bộ phận"" từ mục tin ""Lô hàng"", đối với các lô hàng không liên kết với yêu cầu kiểm soát chất lượng hàng hóa';
								|ru = '- Заполнение нового реквизита ""Подразделение"" из реквизита ""Партия"", для партий, не связанных с заявками на контроль качества товаров';
								|en = '- Fill in the new ""Business unit"" attribute from the ""Lot"" attribute for lots not related to requests for goods quality control'; fa = '- Fill in the new ""Business unit"" attribute from the ""Lot"" attribute for lots not related to requests for goods quality control';
								|it = '- Fill in the new ""Business unit"" attribute from the ""Lot"" attribute for lots not related to requests for goods quality control';
								|pl = '- Fill in the new ""Business unit"" attribute from the ""Lot"" attribute for lots not related to requests for goods quality control';
								|tr = '- Ürün kalite kontrol talepleriyle ilişkili olmayan lotlar için ""Lot"" özniteliğinden yeni ""Departman"" özniteliğinin doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.ReturnOfGoodsFromCustomer.FullName());
	ItemsToRead.Add(Metadata.Documents.MovementOfProductsAndMaterials.FullName());
	ItemsToRead.Add(Metadata.Documents.MaterialProviderOrder2_5.FullName());
	ItemsToRead.Add(Metadata.Documents.TransferOrder.FullName());
	ItemsToRead.Add(Metadata.Documents.ByAssemblyDisassemblyOrder.FullName());
	ItemsToRead.Add(Metadata.Documents.SubcontractOrder2_5.FullName());
	ItemsToRead.Add(Metadata.Documents.PurchaseOrder.FullName());
	ItemsToRead.Add(Metadata.Documents.RequestForReturnOfGoodsFromCustomer.FullName());
	ItemsToRead.Add(Metadata.Documents.InventoryTransfer.FullName());
	ItemsToRead.Add(Metadata.Documents.ReceiptOfGoodsToWarehouse.FullName());
	ItemsToRead.Add(Metadata.Documents.GoodsReceiptFromCustomer.FullName());
	ItemsToRead.Add(Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName());
	ItemsToRead.Add(Metadata.Documents.GoodsReceiptForStorage.FullName());
	ItemsToRead.Add(Metadata.Documents.VendorInvoice.FullName());
	ItemsToRead.Add(Metadata.Documents.OtherGoodsRecordingAsReceived.FullName());
	ItemsToRead.Add(Metadata.Documents.AssemblyFromComponents.FullName());
	ItemsToRead.Add(Metadata.Catalogs.CounterpartyContracts.FullName());
	
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.ControlledLots.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.ControlledLots.ProcessControlledBatchesOfApplicationsForQualityControlOfGoods";
	Handler.Version = "11.5.27.26";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("e7903a65-98ce-4d6d-9e79-8c75b675fdfb");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.ControlledLots.RegisterControlledBatchesOfApplicationsForQualityControlOfGoods";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Lô hàng được kiểm soát"":';
								|ru = 'Обновление справочника ""Контролируемые партии"":';
								|en = 'Update the ""Controlled lots"" catalog:'; fa = 'Update the ""Controlled lots"" catalog:';
								|it = 'Update the ""Controlled lots"" catalog:';
								|pl = 'Update the ""Controlled lots"" catalog:';
								|tr = '""Kontrol edilen lotlar"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = 'Điền giá trị cho mục tin mới ""Bộ phận"" từ các lô hàng của chứng từ, đối với các lô hàng liên kết với yêu cầu kiểm soát chất lượng hàng hóa';
								|ru = '- Заполнение нового реквизита ""Подразделение"" из партий документа, для партий, связанных с заявками на контроль качества товаров';
								|en = '- Fill in the new ""Business unit"" attribute from document lots for lots related to requests for goods quality control'; fa = '- Fill in the new ""Business unit"" attribute from document lots for lots related to requests for goods quality control';
								|it = '- Fill in the new ""Business unit"" attribute from document lots for lots related to requests for goods quality control';
								|pl = '- Fill in the new ""Business unit"" attribute from document lots for lots related to requests for goods quality control';
								|tr = '- Ürün kalite kontrol talepleriyle ilişkili lotlar için belge lotlarından yeni ""Departman"" özniteliğinin doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.ControlledLots.FullName());
	ItemsToRead.Add(Metadata.Documents.RequestForGoodsQualityControl.FullName());
	
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.ControlledLots.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "Catalogs.ControlledLots.ProcessDataForMigrationToNewVersion";
	NewRow.Order = "After";
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	SelectionParameters.AdditionalDataSources.Insert("Lot");
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	Lots.Ref AS Ref
	|FROM
	|	Catalog.ControlledLots AS Lots
	|WHERE
	|	NOT Lots.DeleteBusinessUnitProcessed
	|	AND NOT VALUETYPE(Lots.Lot) = TYPE(Document.RequestForGoodsQualityControl)";
	BatchTable_ = Query.Execute().Unload();
	InfobaseUpdate.MarkForProcessing(Parameters, BatchTable_.UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	
	FullObjectName = EmptyRef().Metadata().FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
		
	EndIf;
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	UpdatedData.Ref AS Ref
	|INTO UpdatedData
	|FROM
	|	&UpdatedData AS UpdatedData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UpdatedData.Ref AS Ref,
	|	CatalogAttributes.Lot AS Lot,
	|	CatalogAttributes.DataVersion AS DataVersion
	|FROM
	|	UpdatedData AS UpdatedData
	|		LEFT JOIN Catalog.ControlledLots AS CatalogAttributes
	|		ON CatalogAttributes.Ref = UpdatedData.Ref";
	
	Query.SetParameter("UpdatedData", UpdatedData);
	
	Selection = Query.Execute().Select();
	
	ExceptionsWhenUpdating = New Array();
	While Selection.Next() Do
		
		ExceptionReason = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "BLOCK";
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Selection.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			If ValueIsFilled(Selection.Lot) Then
				LockItem = Block.Add(Selection.Lot.Metadata().FullName());
				LockItem.SetValue("Ref", Selection.Lot);
				LockItem.Mode = DataLockMode.Shared;
			EndIf;
			
			Block.Lock();
			
			CatalogObject = InfobaseUpdateTM.CheckGetObject(
				Selection.Ref, Selection.DataVersion, Parameters.Queue); // CatalogObject
			
			ExceptionReason = "BAD_DATA";
			
			ObjectModified = False;
			
			If CatalogObject <> Undefined Then
				
				If ValueIsFilled(Selection.Lot)
						And (TypeOf(Selection.Lot) = Type("DocumentRef.ReturnOfGoodsFromCustomer")
							Or TypeOf(Selection.Lot) = Type("DocumentRef.MaterialProviderOrder2_5")
							Or TypeOf(Selection.Lot) = Type("DocumentRef.TransferOrder")
							Or TypeOf(Selection.Lot) = Type("DocumentRef.ByAssemblyDisassemblyOrder")
							Or TypeOf(Selection.Lot) = Type("DocumentRef.SubcontractOrder2_5")
							Or TypeOf(Selection.Lot) = Type("DocumentRef.PurchaseOrder")
							Or TypeOf(Selection.Lot) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
							Or TypeOf(Selection.Lot) = Type("DocumentRef.InventoryTransfer")
							Or TypeOf(Selection.Lot) = Type("DocumentRef.ReceiptOfGoodsToWarehouse")
							Or TypeOf(Selection.Lot) = Type("DocumentRef.GoodsReceiptFromCustomer")
							Or TypeOf(Selection.Lot) = Type("DocumentRef.ReceiptOfGoodsFromCustodian")
							Or TypeOf(Selection.Lot) = Type("DocumentRef.GoodsReceiptForStorage")
							Or TypeOf(Selection.Lot) = Type("DocumentRef.VendorInvoice")
							Or TypeOf(Selection.Lot) = Type("DocumentRef.OtherGoodsRecordingAsReceived")
							Or TypeOf(Selection.Lot) = Type("DocumentRef.AssemblyFromComponents")
							Or TypeOf(Selection.Lot) = Type("CatalogRef.CounterpartyContracts")) Then
								
								AttributeValue = Common.ObjectAttributeValue(Selection.Lot, "Department");
								CatalogObject.Department = AttributeValue;
								
				EndIf;
				CatalogObject.DeleteBusinessUnitProcessed = True;
				
				ObjectModified = True;
				
			EndIf;
			
			ExceptionReason = "RECORD";
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(CatalogObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
			If ExceptionReason = "BAD_DATA" Then
				
				Recommendation = NStr("vi = 'Hãy kiểm tra thủ công dữ liệu danh mục.';
										|ru = 'Проверьте данные справочника вручную.';
										|en = 'Check the catalog data manually.'; fa = 'Check the catalog data manually.';
										|it = 'Проверьте данные справочника вручную.';
										|pl = 'Check the catalog data manually.';
										|tr = 'Dizin verilerini manuel olarak kontrol edin.'");
				IssueDetails = InfobaseUpdateTM.DataProblem(
					Selection.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = "RECORD" Then
				
				InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, 1, Parameters);
				ExceptionText = NStr("vi = 'Không thể xử lý danh mục ""Lô hàng được kiểm soát"".';
									|ru = 'Не удалось обработать справочник ""Контролируемые партии"".';
									|en = 'Cannot process the ""Controlled lots"" catalog.'; fa = 'Cannot process the ""Controlled lots"" catalog.';
									|it = 'Cannot process the ""Controlled lots"" catalog.';
									|pl = 'Cannot process the ""Controlled lots"" catalog.';
									|tr = '""Kontrol edilen lotlar"" kataloğu işlenemedi.'");
				Raise StrConcat(ExceptionText, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, 1, Parameters);
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(
		Parameters.Queue, FullObjectName);
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterControlledBatchesOfApplicationsForQualityControlOfGoods(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	SelectionParameters.AdditionalDataSources.Insert("Lot");
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	Lots.Ref AS Ref
	|FROM
	|	Catalog.ControlledLots AS Lots
	|WHERE
	|	NOT Lots.DeleteBusinessUnitProcessed
	|	AND VALUETYPE(Lots.Lot) = TYPE(Document.RequestForGoodsQualityControl)";
	BatchTable_ = Query.Execute().Unload();
	InfobaseUpdate.MarkForProcessing(Parameters, BatchTable_.UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessControlledBatchesOfApplicationsForQualityControlOfGoods(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	
	FullObjectName = EmptyRef().Metadata().FullName();
	
	If InfobaseUpdate.HasDataLockedByPreviousQueues(Parameters.Queue, FullObjectName) Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf;
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
		
	EndIf;
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	UpdatedData.Ref AS Ref
	|INTO UpdatedData
	|FROM
	|	&UpdatedData AS UpdatedData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UpdatedData.Ref AS Ref,
	|	CatalogAttributes.Lot AS Lot,
	|	CatalogAttributes.DataVersion AS DataVersion
	|FROM
	|	UpdatedData AS UpdatedData
	|		LEFT JOIN Catalog.ControlledLots AS CatalogAttributes
	|		ON CatalogAttributes.Ref = UpdatedData.Ref";
	
	Query.SetParameter("UpdatedData", UpdatedData);
	
	Selection = Query.Execute().Select();
	
	ExceptionsWhenUpdating = New Array();
	While Selection.Next() Do
		
		ExceptionReason = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "BAD_DATA";
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Selection.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			If ValueIsFilled(Selection.Lot) Then
				LockItem = Block.Add(Selection.Lot.Metadata().FullName());
				LockItem.SetValue("Ref", Selection.Lot);
				LockItem.Mode = DataLockMode.Shared;
				
				Query = New Query();
				Query.Text =
					"SELECT DISTINCT
					|	Goods.ControlledLotReference AS ControlledLotReference
					|FROM
					|	Document.RequestForGoodsQualityControl.Goods AS Goods
					|WHERE
					|	Goods.Ref = &RequestForControl
					|	AND Goods.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef)";
				Query.SetParameter("RequestForControl", Selection.Lot);
				ResultOfBatchRequest = Query.Execute();
				LockItem = Block.Add("Catalog.ControlledLots");
				LockItem.DataSource = ResultOfBatchRequest;
				LockItem.UseFromDataSource("Ref", "ControlledLotReference");
				LockItem.Mode = DataLockMode.Shared;
				
			EndIf;
			
			ExceptionReason = "BLOCK";
			Block.Lock();
			
			CatalogObject = InfobaseUpdateTM.CheckGetObject(
				Selection.Ref, Selection.DataVersion, Parameters.Queue); // CatalogObject
			
			ExceptionReason = "BAD_DATA";
			
			ObjectModified = False;
			
			If CatalogObject <> Undefined Then
				
				Query = New Query();
				Query.Text =
					"SELECT
					|	MIN(Goods.ControlledLotReference.Department) AS MinimumDivision,
					|	MAX(Goods.ControlledLotReference.Department) AS MaximumDivision
					|FROM
					|	Document.RequestForGoodsQualityControl.Goods AS Goods
					|WHERE
					|	Goods.Ref = &RequestForControl";
				Query.SetParameter("RequestForControl", Selection.Lot);
				SelectionOfApplications = Query.Execute().Select();
				If SelectionOfApplications.Next()
						And ValueIsFilled(SelectionOfApplications.MinimumDivision)
						And ValueIsFilled(SelectionOfApplications.MaximumDivision)
						And SelectionOfApplications.MinimumDivision = SelectionOfApplications.MaximumDivision Then
							CatalogObject.Department = SelectionOfApplications.MaximumDivision;
				EndIf;
				CatalogObject.DeleteBusinessUnitProcessed = True;
				
				ObjectModified = True;
				
			EndIf;
			
			ExceptionReason = "RECORD";
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(CatalogObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
			If ExceptionReason = "BAD_DATA" Then
				
				Recommendation = NStr("vi = 'Hãy kiểm tra thủ công dữ liệu danh mục.';
										|ru = 'Проверьте данные справочника вручную.';
										|en = 'Check the catalog data manually.'; fa = 'Check the catalog data manually.';
										|it = 'Проверьте данные справочника вручную.';
										|pl = 'Check the catalog data manually.';
										|tr = 'Dizin verilerini manuel olarak kontrol edin.'");
				IssueDetails = InfobaseUpdateTM.DataProblem(
					Selection.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = "RECORD" Then
				
				InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, 1, Parameters);
				ExceptionText = NStr("vi = 'Không thể xử lý danh mục ""Lô hàng được kiểm soát"".';
									|ru = 'Не удалось обработать справочник ""Контролируемые партии"".';
									|en = 'Cannot process the ""Controlled lots"" catalog.'; fa = 'Cannot process the ""Controlled lots"" catalog.';
									|it = 'Cannot process the ""Controlled lots"" catalog.';
									|pl = 'Cannot process the ""Controlled lots"" catalog.';
									|tr = '""Kontrol edilen lotlar"" kataloğu işlenemedi.'");
				Raise StrConcat(ExceptionText, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, 1, Parameters);
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(
		Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf