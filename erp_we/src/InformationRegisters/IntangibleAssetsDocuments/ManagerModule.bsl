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
	Handler.Procedure = "InformationRegisters.IntangibleAssetsDocuments.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.27.30";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("2242cd40-de88-467e-b44d-8c0e6b1e56b3");
	Handler.UpdateDataFillingProcedure = "InformationRegisters.IntangibleAssetsDocuments.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.Comment = NStr("vi = 'Cập nhật biểu ghi ""Chứng từ theo TSCĐ vô hình"" theo dữ liệu của chứng từ gốc.
	|Trước khi công việc của hàm sự kiện kết thúc, nhật ký chứng từ theo TSCĐ vô hình có thể làm việc không chính xác.';
	|ru = 'Обновляет регистр ""Документы по НМА"" по данным исходных документов.
	|Пока работа обработчика не завершена, журнал документов по НМА может работать некорректно.';
	|en = 'Updates the ""Intangible assets documents"" register based on data of source documents.
	|Until the handler execution is finished, the document journal of Intangible assets might function incorrectly.'; fa = 'Updates the ""Intangible assets documents"" register based on data of source documents.
	|Until the handler execution is finished, the document journal of Intangible assets might function incorrectly.';
	|it = 'Обновляет регистр ""Документы по НМА"" по данным исходных документов.
	|Пока работа обработчика не завершена, журнал документов по НМА может работать некорректно.';
	|pl = 'Updates the ""Intangible assets documents"" register based on data of source documents.
	|Until the handler execution is finished, the document journal of Intangible assets might function incorrectly.';
	|tr = 'Kaynak belgelerin verilerine göre ""Maddi olmayan duran varlıklara ilişkin belgeler"" kaydını günceller.
	|İşleyici çalışması tamamlanana kadar, maddi olmayan duran varlık ile ilgili belge günlüğü hatalı çalışabilir.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.EntryOfCapitalAssetsBalance2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.InventoryConsumption.FullName());
	ItemsToRead.Add(Metadata.Documents.ChangeIntangibleAssetFinancialDetails2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.IntangibleAssetsPhysicalCount.FullName());
	ItemsToRead.Add(Metadata.Documents.IntangibleAssetsCostAndAmortizationAdjustment.FullName());
	ItemsToRead.Add(Metadata.Documents.IATransfer2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.PreparingForIntangibleAssetSale2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.IntangibleAssetsInitialRecognition2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.VendorInvoice.FullName());
	ItemsToRead.Add(Metadata.Documents.VendorInvoiceServicesAndAssets.FullName());
	ItemsToRead.Add(Metadata.Documents.CustomerInvoiceServicesAndAssets.FullName());
	ItemsToRead.Add(Metadata.Documents.DisposeIntangibleAssets2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.IntangibleAssetImprovement.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.IntangibleAssetsDocuments.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.InformationRegisters.IntangibleAssetsDocuments.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.IntangibleAssetsDocuments";
	RegisterName = "IntangibleAssetsDocuments";
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", "InformationRegister.IntangibleAssetsDocuments");

	#Region Custom
	
	QueryText =
	"SELECT DISTINCT
	|	DocumentsList.Ref AS Ref
	|FROM
	|	(SELECT
	|		DocumentData.Ref
	|	FROM
	|		Document.IntangibleAssetsPhysicalCount AS DocumentData
	|
	|			LEFT JOIN InformationRegister.IntangibleAssetsDocuments AS IntangibleAssetsDocuments
	|			ON IntangibleAssetsDocuments.Ref = DocumentData.Ref
	|
	|	WHERE
	|		NOT DocumentData.RecordInManAccounting
	|			AND NOT DocumentData.RecordInLocalAccounting
	|			AND NOT DocumentData.PostInAccounting
	|			AND NOT DocumentData.RecordInTA
	|		OR DocumentData.RecordInManAccounting <> ISNULL(IntangibleAssetsDocuments.RecordInManAccounting, FALSE)
	|		OR DocumentData.PostInAccounting <> ISNULL(IntangibleAssetsDocuments.RecordInLocalAccounting, FALSE)
	|		OR DocumentData.RecordInTA <> ISNULL(IntangibleAssetsDocuments.RecordInTA, FALSE)
	|
	|	UNION ALL
	|
	|	SELECT
	|		TableOfIA.Ref
	|	FROM
	|		Document.InventoryConsumption.Goods AS TableOfIA
	|
	|			LEFT JOIN InformationRegister.IntangibleAssetsDocuments AS IntangibleAssetsDocuments
	|			ON IntangibleAssetsDocuments.Ref = TableOfIA.Ref
	|				AND IntangibleAssetsDocuments.RecNo = 0
	|
	|	WHERE
	|		(IntangibleAssetsDocuments.Ref IS NULL
	|			OR NOT ISNULL(IntangibleAssetsDocuments.RecordInTA, FALSE))
	|
	|		AND (TableOfIA.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			OR TableOfIA.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			OR TableOfIA.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|
	|		AND TableOfIA.DimensionOfExpenses <> UNDEFINED
	|		AND TableOfIA.DimensionOfExpenses REFS Catalog.IntangibleAssets
	|		AND TableOfIA.DimensionOfExpenses <> VALUE(Catalog.IntangibleAssets.EmptyRef)
	|
	|	UNION ALL
	|
	|	SELECT
	|		TableOfIA.Ref
	|	FROM
	|		Document.VendorInvoiceServicesAndAssets.Expenses AS TableOfIA
	|
	|			LEFT JOIN InformationRegister.IntangibleAssetsDocuments AS IntangibleAssetsDocuments
	|			ON IntangibleAssetsDocuments.Ref = TableOfIA.Ref
	|				AND IntangibleAssetsDocuments.RecNo = 0
	|
	|	WHERE
	|		(IntangibleAssetsDocuments.Ref IS NULL
	|			OR NOT ISNULL(IntangibleAssetsDocuments.RecordInTA, FALSE))
	|
	|		AND (TableOfIA.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			OR TableOfIA.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			OR TableOfIA.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|
	|		AND TableOfIA.DimensionOfExpenses <> UNDEFINED
	|		AND TableOfIA.DimensionOfExpenses REFS Catalog.IntangibleAssets
	|		AND TableOfIA.DimensionOfExpenses <> VALUE(Catalog.IntangibleAssets.EmptyRef)
	|
	|	UNION ALL
	|
	|	SELECT
	|		TableOfIA.Ref
	|	FROM
	|		Document.VendorInvoice.Goods AS TableOfIA
	|
	|			LEFT JOIN InformationRegister.IntangibleAssetsDocuments AS IntangibleAssetsDocuments
	|			ON IntangibleAssetsDocuments.Ref = TableOfIA.Ref
	|				AND IntangibleAssetsDocuments.RecNo = 0
	|
	|	WHERE
	|		IntangibleAssetsDocuments.Ref IS NULL
	|
	|		AND TableOfIA.ToExpenseAs
	|
	|		AND (TableOfIA.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			OR TableOfIA.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			OR TableOfIA.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|
	|		AND TableOfIA.DimensionOfExpenses <> UNDEFINED
	|		AND TableOfIA.DimensionOfExpenses REFS Catalog.IntangibleAssets
	|		AND TableOfIA.DimensionOfExpenses <> VALUE(Catalog.IntangibleAssets.EmptyRef)
	|
	|	) AS DocumentsList
	|";
	
	Query = New Query(QueryText);

	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload(), AdditionalParameters);
	
	#EndRegion
	
	#Region AdaptedCaseSensitiveQueryText
	
	DocumentsList = New Array;
	DocumentsList.Add("Document.EntryOfCapitalAssetsBalance2_4");
	DocumentsList.Add("Document.ChangeIntangibleAssetFinancialDetails2_4");
	DocumentsList.Add("Document.IntangibleAssetsCostAndAmortizationAdjustment");
	DocumentsList.Add("Document.IATransfer2_4");
	DocumentsList.Add("Document.PreparingForIntangibleAssetSale2_4");
	DocumentsList.Add("Document.IntangibleAssetsInitialRecognition2_4");
	DocumentsList.Add("Document.CustomerInvoiceServicesAndAssets");
	DocumentsList.Add("Document.DisposeIntangibleAssets2_4");
	DocumentsList.Add("Document.IntangibleAssetImprovement");

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
	ItemsToRead.Add(Metadata.Documents.ChangeIntangibleAssetFinancialDetails2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.IntangibleAssetsPhysicalCount.FullName());
	ItemsToRead.Add(Metadata.Documents.IntangibleAssetsCostAndAmortizationAdjustment.FullName());
	ItemsToRead.Add(Metadata.Documents.IATransfer2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.PreparingForIntangibleAssetSale2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.IntangibleAssetsInitialRecognition2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.VendorInvoice.FullName());
	ItemsToRead.Add(Metadata.Documents.VendorInvoiceServicesAndAssets.FullName());
	ItemsToRead.Add(Metadata.Documents.CustomerInvoiceServicesAndAssets.FullName());
	ItemsToRead.Add(Metadata.Documents.DisposeIntangibleAssets2_4.FullName());
	ItemsToRead.Add(Metadata.Documents.IntangibleAssetImprovement.FullName());

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
							"InformationRegister.IntangibleAssetsDocuments",
							Parameters.Queue,
							AdditionalParameters);
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
