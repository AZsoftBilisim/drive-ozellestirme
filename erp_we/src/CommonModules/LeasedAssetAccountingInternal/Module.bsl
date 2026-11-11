////////////////////////////////////////////////////////////////////////////////
// Contains the service procedures and functions of the "Lease" subsystem.
// 
////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Checks that you can fill out a document based on the lease agreement.
// 
// Parameters:
// 	Contract - CatalogRef.LeaseContract -
// 	
// Returns:
// 		- Structure - contains THE Attributes of THE Contract:
//			* Organization - CatalogRef.Companies -
//			* Partner - CatalogRef.Partners - 
//			* Counterparty - CatalogRef.Counterparties -
//			* ARAPCurrency - CatalogRef.Currencies -
//			* VATTaxation - EnumRef.VATTaxationTypes -
//			* ThereIsBuyoutOfLeasedAssets - Boolean - 
//		- Undefined
//
Function CheckDetailsOfLeaseAgreement(Contract) Export
	
	QueryText = 
	"SELECT
	|	LeaseContract.Organization,
	|	LeaseContract.Partner,
	|	LeaseContract.Counterparty,
	|	LeaseContract.ARAPCurrency,
	|	LeaseContract.ThereIsBuyoutOfLeasedAssets,
	|	LeaseContract.DeletionMark,
	|	LeaseContract.VATTaxation,
	|	ISNULL(TermsOfLeaseContracts.State, UNDEFINED) AS State
	|FROM
	|	Catalog.LeaseContract AS LeaseContract
	|		LEFT JOIN InformationRegister.TermsOfLeaseContracts.SliceLast(&Date, Contract = &Contract) AS TermsOfLeaseContracts
	|		ON TermsOfLeaseContracts.Contract = &Contract
	|WHERE
	|	LeaseContract.Ref = &Contract";
	
	Query = New Query(QueryText);
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("Date", CurrentSessionDate());
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	If Selection.DeletionMark Then
		ErrorText = NStr("vi = 'Hợp đồng đã bị đặt dấu xóa, không thể tạo chứng từ';
						|ru = 'Договор помечен на удаление, создание документа недоступно';
						|en = 'The contract is marked for deletion, document creation is not available'; fa = 'The contract is marked for deletion, document creation is not available';
						|it = 'Договор помечен на удаление, создание документа недоступно';
						|pl = 'Umowa jest zaznaczona do usunięcia, utworzenie dokumentu jest niedostępne';
						|tr = 'Sözleşme silinmek üzere işaretlendi, belgenin oluşturulması mevcut değil'");
		Raise ErrorText
	ElsIf Selection.State <> Enums.CounterpartyContractStates.Valid Then
		ErrorText = NStr("vi = 'Không ký kết hợp đồng hoặc hợp đồng không có hiệu lực, không thể tạo chứng từ';
						|ru = 'Не оформлено заключение договора или договор не действует, создание документа недоступно';
						|en = 'The contract signing is not registered or the contract is not valid, creation of document is not available'; fa = 'The contract signing is not registered or the contract is not valid, creation of document is not available';
						|it = 'Не оформлено заключение договора или договор не действует, создание документа недоступно';
						|pl = 'Nie utworzono zawarcia umowy lub umowa nie jest ważna, utworzenie dokumentu jest niedostępne';
						|tr = 'Sözleşmenin imzalanması resmileştirilmemiştir veya sözleşme geçerli değildir, belgenin oluşturulması mevcut değildir'");
		Raise ErrorText
	EndIf;
	
	ContractDetails_ = New Structure;
	ContractDetails_.Insert("Organization", Selection.Organization);
	ContractDetails_.Insert("Partner", Selection.Partner);
	ContractDetails_.Insert("Counterparty", Selection.Counterparty);
	ContractDetails_.Insert("ARAPCurrency", Selection.ARAPCurrency);
	ContractDetails_.Insert("ThereIsBuyoutOfLeasedAssets", Selection.ThereIsBuyoutOfLeasedAssets);
	ContractDetails_.Insert("VATTaxation", Selection.VATTaxation);
	
	Return ContractDetails_;
	
EndFunction

// Checks that the OS has been leased (off-balance sheet accounting).
// 
// Parameters:
// 	Object - DocumentObject.ReceiveLeasedAssets - 
// 	Cancel - Boolean -
Procedure CheckThatFAHasNotBeenLeasedForBalance(Object, Cancel) Export
	
	QueryText = 
	"SELECT
	|	PRESENTATION(LeasedAsset.Recorder) AS PresentationOfDocument,
	|	LeasedAsset.FixedAsset AS LinkToFA,
	|	LeasedAsset.FixedAsset.Presentation AS PresentationFA
	|FROM
	|	InformationRegister.LeasedAsset.SliceLast(
	|			&Period,
	|			Recorder <> &Ref
	|				AND FixedAsset IN (&ListOfFA)) AS LeasedAsset
	|WHERE
	|	LeasedAsset.State = VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting)";
		
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Period", Object.Date);
	Query.SetParameter("ListOfFA", Object.FA.UnloadColumn("FixedAsset"));
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		MessageText = NStr("vi = 'Tài sản cố định ""%1"" không đưa vào thuê (kế toán ngoài bảng). Xem %2.';
							|ru = 'Основное средство ""%1"" уже поступало в аренду (забалансовый учет). См. %2';
							|en = 'The %1 fixed asset is already leased (off-balance accounting). See %2'; fa = 'The %1 fixed asset is already leased (off-balance accounting). See %2';
							|it = 'Основное средство ""%1"" уже поступало в аренду (забалансовый учет). См. %2';
							|pl = 'The %1 fixed asset is already leased (off-balance accounting). See %2';
							|tr = 'Sabit kıymet ""%1"" hali hazırda kiralanmış (bilanço dışı muhasebe). Bkz. %2'");
		MessageText = StrTemplate(MessageText, Selection.PresentationFA, Selection.PresentationOfDocument);
			
		RowData = Object.FA.Find(Selection.LinkToFA, "FixedAsset");
		Path = CommonClientServer.PathToTabularSection("FA", RowData.LineNumber, "FixedAsset");
		Common.MessageToUser(MessageText, Object, Path,, Cancel);
		
	EndDo;
	
EndProcedure

#EndRegion
