#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Defines the composition of documents and business operations that are available for display in the workplace.
//
// Parameters:
//  BusinessTransactionsAndDocuments	 - ValueTable - Table of values with columns:
//     * BusinessOperation					 - EnumRef.BusinessTransactions
//     * MetadataObjectID			 - CatalogRef.MetadataObjectIDs
//     * Filter									 - Boolean
//     * DocumentPresentation					 - String
//     * FullDocumentName						 - String
//     * Invoice								 - Boolean
//     * ReferenceIsUsed				 - Boolean
//     * StatusesAreUsed					 - Boolean
//     * BySeveralOrders					 - Boolean
//     * GoodsReceiptNoteIsImpossible				 - Boolean
//     * DivideDocumentsByDepartment		 - Boolean
//     * InvoiceFullName						 - String
//     * PurposeUseKey			 - String
//     * AccessRightInsert					 - Boolean
//     * AccessRightUpdate					 - Boolean
//     * WorkplaceTitle					 - String
//     * NamesOfElementsWithManagedVisibility	 - String
//     * WorkplaceItemNames			 - String
//     * NamesOfDisplayedElements				 - String
//     * HyperlinkCalculationManagerForRegistration	 - String
//  FilterBusinessTransactions		 - ValueList - list of values of the enum type Link.Economic operations
//  FilterDocumentTypes				 - ValueList - list of values of the reference Link type.IDs of metadata objectsreferences
//  PurposeUseKey		 - String - key of the workplace for which the function is called
//  UnregisteredDocuments			 - Boolean - indicates whether to call the method for the form "Formspiskakoformleniyu".
// 
// Returns:
//   - ValueTable - Table of values with columns:
//     * BusinessOperation					 - EnumRef.BusinessTransactions
//     * MetadataObjectID			 - CatalogRef.MetadataObjectIDs
//     * Filter									 - Boolean
//     * DocumentPresentation					 - String
//     * FullDocumentName						 - String
//     * Invoice								 - Boolean
//     * ReferenceIsUsed				 - Boolean
//     * StatusesAreUsed					 - Boolean
//     * BySeveralOrders					 - Boolean
//     * GoodsReceiptNoteIsImpossible				 - Boolean
//     * DivideDocumentsByDepartment		 - Boolean
//     * InvoiceFullName						 - String
//     * PurposeUseKey			 - String
//     * AccessRightInsert					 - Boolean
//     * AccessRightUpdate					 - Boolean
//     * WorkplaceTitle					 - String
//     * NamesOfElementsWithManagedVisibility	 - String
//     * WorkplaceItemNames			 - String
//     * NamesOfDisplayedElements				 - String
//     * HyperlinkCalculationManagerForRegistration	 - String
//
//
Function InitializeBusinessTransactionsAndDocuments(BusinessTransactionsAndDocuments, FilterBusinessTransactions, FilterDocumentTypes, PurposeUseKey, UnregisteredDocuments = False) Export
	
	// InventoryConsumption
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.TransferToOperation;
	String.DocumentType                 = Type("DocumentRef.InventoryConsumption");
	String.FullDocumentName			= Metadata.Documents.InventoryConsumption.FullName();
	String.DocumentPresentation        = NStr("vi = 'Đưa vào sử dụng';
												|ru = 'Передача в эксплуатацию';
												|en = 'Commissioning'; fa = 'بهره‌برداری';
												|it = 'Consegna in esercizio';
												|pl = 'Przekazanie do eksploatacji';
												|tr = 'Ekipman çıkışı'");
	String.ButtonGroup                 = "TransferToOperation";
	String.Order                      = 2;
	String.AddButtonCreate        = True;
	
	// InventoryConsumptionOrder
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.TransferToOperation;
	String.DocumentType                 = Type("DocumentRef.InventoryConsumptionOrder");
	String.FullDocumentName			= Metadata.Documents.InventoryConsumptionOrder.FullName();
	String.DocumentPresentation        = NStr("vi = 'Lệnh đưa vào hoạt động';
												|ru = 'Заказ на передачу в эксплуатацию';
												|en = 'Commissioning order'; fa = 'Commissioning order';
												|it = 'Заказ на передачу в эксплуатацию';
												|pl = 'Commissioning order';
												|tr = 'Kullanıma aktarma emri'");
	String.ButtonGroup                 = "TransferToOperation";
	String.Order                      = 1;
	String.AddButtonCreate        = True;
	
	// TransferInOperation
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.TransferInOperation;
	String.DocumentType                 = Type("DocumentRef.TransferInOperation");
	String.FullDocumentName			= Metadata.Documents.TransferInOperation.FullName();
	String.DocumentPresentation        = NStr("vi = 'Điều chuyển trong khi vận hành';
												|ru = 'Перемещение в эксплуатации';
												|en = 'Transfer in operation'; fa = 'انتقال در حال بهره‌برداری';
												|it = 'Movimentazione nell''uso';
												|pl = 'Przeniesienie w eksploatacji';
												|tr = 'Faaliyetteki hareketler'");
	String.ButtonGroup                 = "TransferInOperation";
	String.Order                      = 3;
	String.AddButtonCreate        = True;
	
	// Decomissioning
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.Decomissioning;
	String.DocumentType                 = Type("DocumentRef.Decomissioning");
	String.FullDocumentName			= Metadata.Documents.Decomissioning.FullName();
	String.DocumentPresentation        = NStr("vi = 'Ngừng hoạt động';
												|ru = 'Списание из эксплуатации';
												|en = 'Write-off from operation'; fa = 'اسقاط از بهره‌برداری';
												|it = 'Storno dall''utilizzo';
												|pl = 'Spisanie z eksploatacji';
												|tr = 'Hizmet dışı bırakma'");
	String.ButtonGroup                 = "TransferInOperation";
	String.Order                      = 4;
	String.AddButtonCreate        = True;
	
	// OtherGoodsRecordingAsReceived
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.PutOutOfOperation;
	String.DocumentType                 = Type("DocumentRef.OtherGoodsRecordingAsReceived");
	String.FullDocumentName			= Metadata.Documents.OtherGoodsRecordingAsReceived.FullName();
	String.DocumentPresentation        = NStr("vi = 'Thu lại từ sử dụng';
												|ru = 'Возврат из эксплуатации';
												|en = 'Put out of operation'; fa = 'خارج کردن از بهره‌برداری';
												|it = 'Reso dall''esercizio';
												|pl = 'Zwrot z eksploatacji';
												|tr = 'Ekipman iadesi'");
	String.ButtonGroup                 = "TransferInOperation";
	String.Order                      = 5;
	String.AddButtonCreate        = True;
	
	// RecordInventoryInOperation
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.RecordInventoryInOperation;
	String.DocumentType                 = Type("DocumentRef.RecordInventoryInOperation");
	String.FullDocumentName			= Metadata.Documents.RecordInventoryInOperation.FullName();
	String.DocumentPresentation        = NStr("vi = 'Ghi tăng vật tư đang sử dụng';
												|ru = 'Оприходование в эксплуатации';
												|en = 'Goods receipt in operation'; fa = 'Goods receipt in operation';
												|it = 'Оприходование в эксплуатации';
												|pl = 'Goods receipt in operation';
												|tr = 'Kullanımdaki stok fazlası'");
	String.ButtonGroup                 = "TransferInOperation";
	String.Order                      = 6;
	String.AddButtonCreate        = True;

	// PhysicalCountOfInventoryInOperation
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.PhysicalCountOfInventoryInOperation;
	String.DocumentType                 = Type("DocumentRef.PhysicalCountOfInventoryInOperation");
	String.FullDocumentName			= Metadata.Documents.PhysicalCountOfInventoryInOperation.FullName();
	String.DocumentPresentation        = NStr("vi = 'Kiểm kê';
												|ru = 'Инвентаризация';
												|en = 'Physical inventory count'; fa = 'شمارش فیزیکی موجودی';
												|it = 'Inventariazione';
												|pl = 'Physical inventory count';
												|tr = 'Stok sayımı'");
	String.ButtonGroup                 = "PhysicalCountOfInventoryInOperation";
	String.Order                      = 7;
	String.AddButtonCreate        = True;

	InventoryInOperationLocalization.SupplementBusinessOperationsAndDocuments(BusinessTransactionsAndDocuments);
	
	TableOfValuesAvailable = TMCommonUse.AvailableBusinessTransactionsAndDocuments(
								BusinessTransactionsAndDocuments, 
								FilterBusinessTransactions, 
								FilterDocumentTypes, 
								PurposeUseKey);
	
	Return TableOfValuesAvailable;
		
EndFunction

#Region Commands

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function DefaultFormAssignmentKey() Export
	
	Return "FADocuments";
	
EndFunction

Function WorkplaceData(Parameters) Export

	If Not AccessRight("InteractiveInsert", Metadata.Documents.Decomissioning)
		And Not AccessRight("InteractiveInsert", Metadata.Documents.OtherGoodsRecordingAsReceived)
		And Not AccessRight("InteractiveInsert", Metadata.Documents.InventoryConsumptionOrder) Then
		Return Undefined;
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED TOP 1
	|	TRUE
	|FROM
	|	AccumulationRegister.InventoryInOperation.Balance(
	|		,
	|		(Organization = &Organization
	|				OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|
	|			AND (Department = &Department
	|				OR &Department = VALUE(Catalog.BusinessStructure.EmptyRef))
	|
	|		) AS InventoryInOperation
	|
	|WHERE
	|	InventoryInOperation.CountBalance > 0
	|	AND ISNULL(InventoryInOperation.Lot.CompletionDate_, DATETIME(1,1,1)) < &Period
	|	AND ISNULL(InventoryInOperation.Lot.CompletionDate_, DATETIME(1,1,1)) <> DATETIME(1,1,1)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Period", CurrentSessionDate());
	Query.SetParameter("Organization", Parameters.Organization);
	Query.SetParameter("Department", Parameters.Department);
	
	Result = Query.Execute();
	
	HyperlinkText = NStr("vi = 'Ghi giảm';
						|ru = 'Списание';
						|en = 'Write-off'; fa = 'اسقاط';
						|it = 'Storno';
						|pl = 'Rozchód';
						|tr = 'Gider yazma'");
	If Result.IsEmpty() Then
		ColorOfHyperlink = StyleColors.EmptyTableField;
	Else
		ColorOfHyperlink = Undefined;
	EndIf;
	
	HyperLinkWriteOff = New FormattedString(HyperlinkText,, ColorOfHyperlink,, "#Decomissioning");
	
	Hyperlink = New FormattedString(NStr("vi = 'Cần lập chứng từ:';
										|ru = 'К оформлению:';
										|en = 'To register:'; fa = 'To register:';
										|it = 'In formalizzazione:';
										|pl = 'Do sporządzenia:';
										|tr = 'Düzenlenecek:'"), " ", HyperLinkWriteOff);
	
	Return Hyperlink;
	
EndFunction

#EndRegion

#EndIf
