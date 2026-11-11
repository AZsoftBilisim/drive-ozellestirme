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
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.FixedAssetsDocuments.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.27.30";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("1892904b-52b1-403d-b930-22e24bcc7bf8");
	Handler.UpdateDataFillingProcedure = "InformationRegisters.FixedAssetsDocuments.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.Comment = NStr("vi = 'Cập nhật biểu ghi ""Chứng từ theo TSCĐ"" theo dữ liệu của chứng từ gốc.
	|Trước khi công việc của hàm sự kiện kết thúc, nhật ký chứng từ theo TSCĐ có thể làm việc không chính xác.';
	|ru = 'Обновляет регистр ""Документы по ОС"" по данным исходных документов.
	|Пока работа обработчика не завершена, журнал документов по ОС может работать некорректно.';
	|en = 'Updates the ""Fixed assets documents"" register based on data of source documents.
	|Until the handler execution is finished, the document journal of fixed assets might function incorrectly.'; fa = 'Updates the ""Fixed assets documents"" register based on data of source documents.
	|Until the handler execution is finished, the document journal of fixed assets might function incorrectly.';
	|it = 'Обновляет регистр ""Документы по ОС"" по данным исходных документов.
	|Пока работа обработчика не завершена, журнал документов по ОС может работать некорректно.';
	|pl = 'Updates the ""Fixed assets documents"" register based on data of source documents.
	|Until the handler execution is finished, the document journal of fixed assets might function incorrectly.';
	|tr = 'Kaynak belgelerin verilerine dayanarak ""Sabit kıymet belgeleri"" kaydını günceller.
	|İşleyicinin çalışması tamamlanana kadar, sabit kıymet ile ilgili belgelerin kaydı doğru çalışmayabilir.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.EntryOfCapitalAssetsBalance2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.InventoryConsumption.FullName());
	ItemsToRead.Add(Metadata.Documents.ReturnAssetsFromLeasee2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.VendorInvoiceLeasedAssets.FullName());
	ItemsToRead.Add(Metadata.Documents.ChangeFixedAssetFinancialDetails2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.FixedAssetsPhysicalCount.FullName());
	ItemsToRead.Add(Metadata.Documents.FixedAssetCostAndDepreciationAdjustment.FullName());
	ItemsToRead.Add(Metadata.Documents.FixedAssetsCostAdditions2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.MergeOfFixedAssets.FullName());
	ItemsToRead.Add(Metadata.Documents.ProvideAssetsToLeasee2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.FATransfer2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.FARevaluation2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.PreparingForFixedAssetSale2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.FixedAssetsInitialRecognition2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.VendorInvoice.FullName());
	ItemsToRead.Add(Metadata.Documents.VendorInvoiceServicesAndAssets.FullName());
	ItemsToRead.Add(Metadata.Documents.SplitFixedAssets.FullName());
	ItemsToRead.Add(Metadata.Documents.CustomerInvoiceServicesAndAssets.FullName());
	ItemsToRead.Add(Metadata.Documents.DisposeFixedAssets2_4.FullName());

	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.FixedAssetsDocuments.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.InformationRegisters.FixedAssetsDocuments.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.FixedAssetsDocuments";
	RegisterName = "FixedAssetsDocuments";

	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", "InformationRegister.FixedAssetsDocuments");
	
	#Region Custom
	
	QueryText =
	"SELECT DISTINCT
	|	DocumentsList.Ref AS Ref
	|FROM
	|	(SELECT
	|		DocumentData.Ref
	|	FROM
	|		Document.FixedAssetsPhysicalCount AS DocumentData
	|
	|			LEFT JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|			ON FixedAssetsDocuments.Ref = DocumentData.Ref
	|
	|	WHERE
	|		NOT DocumentData.RecordInManAccounting
	|			AND NOT DocumentData.RecordInLocalAccounting
	|			AND NOT DocumentData.PostInAccounting
	|			AND NOT DocumentData.RecordInTA
	|		OR DocumentData.RecordInManAccounting <> ISNULL(FixedAssetsDocuments.RecordInManAccounting, FALSE)
	|		OR DocumentData.PostInAccounting <> ISNULL(FixedAssetsDocuments.RecordInLocalAccounting, FALSE)
	|		OR DocumentData.RecordInTA <> ISNULL(FixedAssetsDocuments.RecordInTA, FALSE)
	|
	|	UNION ALL
	|
	|	SELECT
	|		FATable.Ref
	|	FROM
	|		Document.InventoryConsumption.Goods AS FATable
	|
	|			LEFT JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|			ON FixedAssetsDocuments.Ref = FATable.Ref
	|				AND FixedAssetsDocuments.RecNo = 0
	|
	|	WHERE
	|		(FixedAssetsDocuments.Ref IS NULL
	|			OR NOT ISNULL(FixedAssetsDocuments.RecordInTA, FALSE))
	|
	|		AND (FATable.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			OR FATable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			OR FATable.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|
	|		AND FATable.DimensionOfExpenses <> UNDEFINED
	|		AND (FATable.DimensionOfExpenses REFS Catalog.Assets
	|				AND FATable.DimensionOfExpenses <> VALUE(Catalog.Assets.EmptyRef)
	|			OR FATable.DimensionOfExpenses REFS Catalog.ConstructionObjects
	|				AND FATable.DimensionOfExpenses <> VALUE(Catalog.ConstructionObjects.EmptyRef))
	|
	|	UNION ALL
	|
	|	SELECT
	|		FATable.Ref
	|	FROM
	|		Document.VendorInvoiceServicesAndAssets.Expenses AS FATable
	|
	|			LEFT JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|			ON FixedAssetsDocuments.Ref = FATable.Ref
	|				AND FixedAssetsDocuments.RecNo = 0
	|
	|	WHERE
	|		(FixedAssetsDocuments.Ref IS NULL
	|			OR NOT ISNULL(FixedAssetsDocuments.RecordInTA, FALSE))
	|
	|		AND (FATable.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			OR FATable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			OR FATable.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|
	|		AND FATable.DimensionOfExpenses <> UNDEFINED
	|		AND (FATable.DimensionOfExpenses REFS Catalog.Assets
	|				AND FATable.DimensionOfExpenses <> VALUE(Catalog.Assets.EmptyRef)
	|			OR FATable.DimensionOfExpenses REFS Catalog.ConstructionObjects
	|				AND FATable.DimensionOfExpenses <> VALUE(Catalog.ConstructionObjects.EmptyRef))
	|
	|	UNION ALL
	|
	|	SELECT
	|		FATable.Ref
	|	FROM
	|		Document.VendorInvoice.Goods AS FATable
	|
	|			LEFT JOIN InformationRegister.FixedAssetsDocuments AS FixedAssetsDocuments
	|			ON FixedAssetsDocuments.Ref = FATable.Ref
	|				AND FixedAssetsDocuments.RecNo = 0
	|
	|	WHERE
	|		FixedAssetsDocuments.Ref IS NULL
	|
	|		AND FATable.ToExpenseAs
	|
	|		AND (FATable.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			OR FATable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			OR FATable.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|
	|		AND FATable.DimensionOfExpenses <> UNDEFINED
	|		AND (FATable.DimensionOfExpenses REFS Catalog.Assets
	|				AND FATable.DimensionOfExpenses <> VALUE(Catalog.Assets.EmptyRef)
	|			OR FATable.DimensionOfExpenses REFS Catalog.ConstructionObjects
	|				AND FATable.DimensionOfExpenses <> VALUE(Catalog.ConstructionObjects.EmptyRef))
	|
	|	) AS DocumentsList
	|";
	
	Query = New Query(QueryText);

	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload(), AdditionalParameters);
	
	#EndRegion
	
	#Region AdaptedCaseSensitiveQueryText
	
	DocumentsList = New Array;
	DocumentsList.Add("Document.EntryOfCapitalAssetsBalance2_4");
	DocumentsList.Add("Document.ReturnAssetsFromLeasee2_4");
	DocumentsList.Add("Document.VendorInvoiceLeasedAssets");
	DocumentsList.Add("Document.ChangeFixedAssetFinancialDetails2_4");
	DocumentsList.Add("Document.FixedAssetCostAndDepreciationAdjustment");
	DocumentsList.Add("Document.FixedAssetsCostAdditions2_4");
	DocumentsList.Add("Document.MergeOfFixedAssets");
	DocumentsList.Add("Document.AllocateVariancesToFixedAssetCost");
	DocumentsList.Add("Document.ProvideAssetsToLeasee2_4");
	DocumentsList.Add("Document.FATransfer2_4");
	DocumentsList.Add("Document.FARevaluation2_4");
	DocumentsList.Add("Document.PreparingForFixedAssetSale2_4");
	DocumentsList.Add("Document.FixedAssetsInitialRecognition2_4");
	DocumentsList.Add("Document.SplitFixedAssets");
	DocumentsList.Add("Document.CustomerInvoiceServicesAndAssets");
	DocumentsList.Add("Document.DisposeFixedAssets2_4");
	
	
	For Each FullDocumentName In DocumentsList Do
		DocumentName = StrSplit(FullDocumentName, ".")[1];
		TextOfRequestOfMechanismOfCarryingOut = Documents[DocumentName].AdaptedCaseSensitiveQueryText(RegisterName);
		Recorders = InfobaseUpdateTM.IndependentRegisterDataForRecheck(
								TextOfRequestOfMechanismOfCarryingOut,
								FullRegisterName,
								FullDocumentName);
								
		InfobaseUpdate.MarkForProcessing(Parameters, Recorders, AdditionalParameters);
	EndDo; 
	
	#EndRegion
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.EntryOfCapitalAssetsBalance2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.InventoryConsumption.FullName());
	ItemsToRead.Add(Metadata.Documents.ReturnAssetsFromLeasee2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.VendorInvoiceLeasedAssets.FullName());
	ItemsToRead.Add(Metadata.Documents.ChangeFixedAssetFinancialDetails2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.FixedAssetsPhysicalCount.FullName());
	ItemsToRead.Add(Metadata.Documents.FixedAssetCostAndDepreciationAdjustment.FullName());
	ItemsToRead.Add(Metadata.Documents.FixedAssetsCostAdditions2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.MergeOfFixedAssets.FullName());
	ItemsToRead.Add(Metadata.Documents.ProvideAssetsToLeasee2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.FATransfer2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.FARevaluation2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.PreparingForFixedAssetSale2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.FixedAssetsInitialRecognition2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.VendorInvoice.FullName());
	ItemsToRead.Add(Metadata.Documents.VendorInvoiceServicesAndAssets.FullName());
	ItemsToRead.Add(Metadata.Documents.SplitFixedAssets.FullName());
	ItemsToRead.Add(Metadata.Documents.CustomerInvoiceServicesAndAssets.FullName());
	ItemsToRead.Add(Metadata.Documents.DisposeFixedAssets2_4.FullName());

	
	For Each FullName In ItemsToRead Do
		
		If InfobaseUpdate.HasDataLockedByPreviousQueues(Parameters.Queue, FullName) Then
			Parameters.ProcessingCompleted = False;
			Return;
		EndIf;
		
	EndDo;

	AdditionalParameters = InfobaseUpdateTM.AdditionalOptionsForOverwritingRegisteredRecordsFromQueue();
	AdditionalParameters.IsIndependentInformationRegister = True;
	AdditionalParameters.NameOfTheDimensionToSelect = "Ref";
	AdditionalParameters.NeedAdditionalRecordProcessing = True;
	
	OrderFields = New Array;
	OrderFields.Add("Ref.Date DESC");
	AdditionalParameters.OrderFields = OrderFields;
	
	ProcessingCompleted = InfobaseUpdateTM.OverwriteRegisteredRecordsFromQueue(
							Undefined,
							"InformationRegister.FixedAssetsDocuments",
							Parameters.Queue,
							AdditionalParameters);
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
