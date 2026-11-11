#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("CatalogRef.InventoryKinds") Then
		InventoryTypeDetails = InventoryTypeDetails(FillingData);
		
		If InventoryTypeDetails.SaleOfAnotherCompanyInventory Then
			Text = NStr("vi = 'Dạng hàng tồn kho được chọn là bán hàng tồn kho cho doanh nghiệp khác';
						|ru = 'Выбранный вид запасов уже является реализацией запасов другой организации';
						|en = 'The selected inventory owner attributes are already a sale of another company''s inventory'; fa = 'The selected inventory owner attributes are already a sale of another company''s inventory';
						|it = 'Il tipo delle scorte selezionato costituisce già il realizzo delle scorte di un''altra organizzazione';
						|pl = 'Wybrany rodzaj pozycji jest już sprzedażą zapasów innej firmy';
						|tr = 'Seçilen stok türü zaten başka bir iş yeri tarafından yapılan stok satışıdır'");
			
			Raise Text;
		EndIf;
		
		SaleOfAnotherCompanyInventory = True;
		InventoryOwnerAttributeOfCompanyGoodsOwner = FillingData;
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If SaleOfAnotherCompanyInventory Then
		Attributes = InventoryTypeDetails(InventoryOwnerAttributeOfCompanyGoodsOwner);
		
		If Attributes.SaleOfAnotherCompanyInventory Then
			MessageText = NStr("vi = 'Chỉ ra dạng hàng tồn kho là bán hàng tồn kho cho doanh nghiệp khác';
								|ru = 'Указан вид запасов являющийся реализацией запасов другой организации';
								|en = 'The selected inventory owner attributes are a sale of another company''s inventory'; fa = 'The selected inventory owner attributes are a sale of another company''s inventory';
								|it = 'Указан вид запасов являющийся реализацией запасов другой организации';
								|pl = 'Wskazano rodzaj pozycji, będący sprzedażą zapasów innej firmy';
								|tr = 'Başka bir iş yerinin stoklarının satışı olan stok türü belirtilir'");
			
			Common.MessageToUser(MessageText, Ref, "InventoryOwnerAttributeOfCompanyGoodsOwner", , Cancel);
		EndIf;
		
		If Attributes.Organization = Organization Then
			MessageText = NStr("vi = 'Doanh nghiệp bằng với doanh nghiệp - người sở hữu hàng hóa';
								|ru = 'Организация равна организации - владельцу товара';
								|en = 'The company matches the goods owner company'; fa = 'The company matches the goods owner company';
								|it = 'Организация равна организации - владельцу товара';
								|pl = 'Firma jest równa firmie właścicielowi towaru';
								|tr = 'İş yeri, iş yerine eşittir - ürünlerin sahibi'");
			
			Common.MessageToUser(MessageText, ThisObject, "Organization", , Cancel);
		EndIf;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If SaleOfAnotherCompanyInventory Then
		If GoodsTransferMethod = Enums.GoodsTransferMethods.TransferToCommissionAgent Then
			CurStockType = Enums.InventoryTypes.ConsignedGoods;
		Else
			CurStockType = Enums.InventoryTypes.OwnGoods;
		EndIf;
		
		If InventoryType <> CurStockType Then
			InventoryType = CurStockType;
		EndIf;
	EndIf;
	
	If InventoryType = Enums.InventoryTypes.ConsignedGoods
		Or InventoryType = Enums.InventoryTypes.ProductsOfMaterialProvider
		Or InventoryType = Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider
		Or InventoryType = Enums.InventoryTypes.MaterialOfMaterialProvider
		Or InventoryType = Enums.InventoryTypes.GoodsInStorageWithRightToSell Then
		
		CleaningOwner = False;
		
	Else
		CleaningOwner = True;
	EndIf;
	
	If CleaningOwner
		And (ValueIsFilled(GoodsOwner)
			Or GoodsOwner <> Undefined) Then
		
		GoodsOwner = Undefined;
		
	ElsIf Not CleaningOwner
		And Not ValueIsFilled(GoodsOwner) Then
		
		ExceptionText = NStr("vi = 'Chưa điền đối tượng chủ đối với dạng vật tư!';
							|ru = 'Для вида запасов не заполнен владелец!';
							|en = 'Owner is required for the inventory owner attributes!'; fa = 'Owner is required for the inventory owner attributes!';
							|it = 'Non è compilato il proprietario per il tipo di scorte!';
							|pl = 'Dla rodzaju zapasów nie wypełniono właściciela!';
							|tr = 'Sahip, stok türü için doldurulmadı!'");
		
		Raise ExceptionText;
		
	EndIf;
	
	If InventoryType <> Enums.InventoryTypes.ConsignedGoods
		And InventoryType <> Enums.InventoryTypes.GoodsInStorageWithRightToSell Then
		
		If ValueIsFilled(Terms) Then
			Terms = Undefined;
		EndIf;
		
		If ValueIsFilled(Currency) Then
			Currency = Undefined;
		EndIf;
		
	EndIf;
	
	If InventoryType <> Enums.InventoryTypes.GoodsInStorageWithRightToSell
		And InventoryType <> Enums.InventoryTypes.OwnGoodsInTransit
		And InventoryType <> Enums.InventoryTypes.OwnGoodsOfUninvoicedDelivery Then
		
		PriceKind = Undefined;
		
	EndIf;
	
	If InventoryType = Enums.InventoryTypes.Work_5 Then
		FinancialAccountingGroup = Undefined;
	EndIf;
	
	If Not SubjectToExcise Then
		BusinessUnitProduction = Undefined;
	EndIf;
	
	Description = NameOfInventoryType(ThisObject);
	
	If Not SaleOfAnotherCompanyInventory
		And ValueIsFilled(InventoryOwnerAttributeOfCompanyGoodsOwner) Then
		
		InventoryOwnerAttributeOfCompanyGoodsOwner = Undefined;
		
	EndIf;
	
	If DeletionMark
		And Not SaleOfAnotherCompanyInventory Then
		
		MarkIntercompanyInventoryTypesForDeletion();
		
	EndIf;
	
	Catalogs.InventoryKinds.HandleObjectAttributes(ThisObject);
	
	If IsNew() Then
		Try
			Catalogs.InventoryKinds.StockTypeStructure(Organization, , ThisObject);
		Except
			ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			
			Common.MessageToUser(ErrorPresentation, , , , Cancel);
		EndTry;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	CheckDuplicates(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

Procedure MarkIntercompanyInventoryTypesForDeletion()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CatalogData.Ref AS Ref
	|FROM
	|	Catalog.InventoryKinds AS CatalogData
	|WHERE
	|	CatalogData.InventoryOwnerAttributeOfCompanyGoodsOwner = &InventoryOwnerAttribute
	|	AND NOT CatalogData.DeletionMark";
	
	Query.SetParameter("InventoryOwnerAttribute", Ref);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		CatalogObject = Selection.Ref.GetObject();
		CatalogObject.SetDeletionMark(True, False);
	EndDo;
	
EndProcedure

Function InventoryTypeDetails(InventoryOwnerAttribute)
	
	InventoryTypeDetails = New Structure;
	InventoryTypeDetails.Insert("SaleOfAnotherCompanyInventory", False);
	InventoryTypeDetails.Insert("Organization", Catalogs.Companies.EmptyRef());
	InventoryTypeDetails.Insert("Currency", Catalogs.Currencies.EmptyRef());
	InventoryTypeDetails.Insert("InventoryType", Enums.InventoryTypes.EmptyRef());
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	InventoryKinds.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	InventoryKinds.Organization AS Organization,
	|	InventoryKinds.Currency AS Currency,
	|	InventoryKinds.InventoryType AS InventoryType
	|FROM
	|	Catalog.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.Ref = &InventoryOwnerAttribute";
	
	Query.SetParameter("InventoryOwnerAttribute", InventoryOwnerAttribute);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return InventoryTypeDetails;
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	FillPropertyValues(InventoryTypeDetails, Selection);
	
	Return InventoryTypeDetails;
	
EndFunction

Function NameOfInventoryType(CatalogObject)
	
	DefaultLanguageCode			= Common.DefaultLanguageCode();
	PresentationOfInventoryType	= Enums.InventoryTypes.RepresentationInLanguage(CatalogObject.InventoryType,
																			DefaultLanguageCode);
	
	PartsOfName = New Array;
	PartsOfName.Add(PresentationOfInventoryType);
	
	If CatalogObject.InventoryType = Enums.InventoryTypes.ConsignedGoods Then
		OwnerPresentation = NStr("vi = 'Người đặt ký gửi:';
								|ru = 'Комитент:';
								|en = 'Consignor:'; fa = 'امانت‌گذار:';
								|it = 'Комитент:';
								|pl = 'Consignor:';
								|tr = 'Gönderici:'", DefaultLanguageCode) + Chars.NBSp
										+ String(CatalogObject.GoodsOwner);
		
		PartsOfName.Add(OwnerPresentation);
		
		If ValueIsFilled(CatalogObject.Terms) Then
			PresentationOfAgreement = NStr("vi = 'Thỏa thuận:';
											|ru = 'Соглашение:';
											|en = 'Agreement:'; fa = 'توافق‌نامه:';
											|it = 'Соглашение:';
											|pl = 'Agreement:';
											|tr = 'Anlaşma:'", DefaultLanguageCode) + Chars.NBSp
											+ String(CatalogObject.Terms);
			
			PartsOfName.Add(PresentationOfAgreement);
		EndIf;
		
		If ValueIsFilled(CatalogObject.Contract) Then
			PresentationOfContract = NStr("vi = 'Hợp đồng:';
											|ru = 'Договор:';
											|en = 'Contract:'; fa = 'قرارداد:';
											|it = 'Договор:';
											|pl = 'Contract:';
											|tr = 'Sözleşme:'", DefaultLanguageCode) + Chars.NBSp
											+ String(CatalogObject.Contract);
			
			PartsOfName.Add(PresentationOfContract);
		EndIf;
		
		PresentationTaxation = Enums.VATTaxationTypes.RepresentationInLanguage(
										CatalogObject.VATTaxation, DefaultLanguageCode);
		CurrencyPresentation = NStr("vi = 'Tiền tệ:';
									|ru = 'Валюта:';
									|en = 'Currency:'; fa = 'ارز:';
									|it = 'Валюта:';
									|pl = 'Currency:';
									|tr = 'Para birimi:'", DefaultLanguageCode) + Chars.NBSp + String(CatalogObject.Currency);
		
		PartsOfName.Add(PresentationTaxation);
		PartsOfName.Add(CurrencyPresentation);
	ElsIf CatalogObject.InventoryType = Enums.InventoryTypes.ProductsOfMaterialProvider
		Or CatalogObject.InventoryType = Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider
		Or CatalogObject.InventoryType = Enums.InventoryTypes.MaterialOfMaterialProvider Then
		
		OwnerPresentation = NStr("vi = 'Người thuê gia công';
								|ru = 'Давалец:';
								|en = 'Material provider:'; fa = 'تأمین‌کننده مواد:';
								|it = 'Давалец:';
								|pl = 'Material provider:';
								|tr = 'Malzeme tedarikçisi:'", DefaultLanguageCode) + Chars.NBSp
										+ String(CatalogObject.GoodsOwner);
		
		PartsOfName.Add(OwnerPresentation);
		
		If ValueIsFilled(CatalogObject.Contract) Then
			PresentationOfContract = NStr("vi = 'Hợp đồng:';
											|ru = 'Договор:';
											|en = 'Contract:'; fa = 'قرارداد:';
											|it = 'Договор:';
											|pl = 'Contract:';
											|tr = 'Sözleşme:'", DefaultLanguageCode) + Chars.NBSp
											+ String(CatalogObject.Contract);
			
			PartsOfName.Add(PresentationOfContract);
		EndIf;
	ElsIf CatalogObject.InventoryType = Enums.InventoryTypes.GoodsInStorageWithRightToSell Then
		OwnerPresentation = NStr("vi = 'Bên gửi hàng:';
								|ru = 'Поклажедатель:';
								|en = 'Depositor:'; fa = 'سپارنده:';
								|it = 'Поклажедатель:';
								|pl = 'Depositor:';
								|tr = 'Kefil:'", DefaultLanguageCode) + Chars.NBSp
										+ String(CatalogObject.GoodsOwner);
		PresentationOfContract = NStr("vi = 'Hợp đồng:';
										|ru = 'Договор:';
										|en = 'Contract:'; fa = 'قرارداد:';
										|it = 'Договор:';
										|pl = 'Contract:';
										|tr = 'Sözleşme:'", DefaultLanguageCode) + Chars.NBSp
											+ String(CatalogObject.Contract);
		
		PartsOfName.Add(OwnerPresentation);
		PartsOfName.Add(PresentationOfContract);
		
		If ValueIsFilled(CatalogObject.PriceKind) Then
			PresentationOfPriceType = NStr("vi = 'Dạng giá:';
											|ru = 'Вид цены:';
											|en = 'Price type:'; fa = 'Price type:';
											|it = 'Вид цены:';
											|pl = 'Rodzaj ceny:';
											|tr = 'Fiyat türü:'", DefaultLanguageCode) + Chars.NBSp
											+ String(CatalogObject.PriceKind);
			
			PartsOfName.Add(PresentationOfPriceType);
		EndIf;
	EndIf;
	
	If ValueIsFilled(CatalogObject.FinancialAccountingGroup) Then
		HFCPresentation = NStr("vi = 'Nhóm:';
								|ru = 'Группа:';
								|en = 'Group:'; fa = 'Group:';
								|it = 'Группа:';
								|pl = 'Group:';
								|tr = 'Grup:'", DefaultLanguageCode) + Chars.NBSp
								+ String(CatalogObject.FinancialAccountingGroup);
		
		PartsOfName.Add(HFCPresentation);
	EndIf;
	
	RepresentationOfTheOrganization = NStr("vi = 'Doanh nghiệp:';
											|ru = 'Организация:';
											|en = 'Company:'; fa = 'شرکت:';
											|it = 'Организация:';
											|pl = 'Company:';
											|tr = 'İş yeri:'", DefaultLanguageCode) + Chars.NBSp
								+ String(CatalogObject.Organization);
	
	PartsOfName.Add(RepresentationOfTheOrganization);
	
	If ValueIsFilled(CatalogObject.ProductsGroup) Then
		PresentationOfProductGroup = NStr("vi = 'Nhóm sản phẩm:';
											|ru = 'Группа продукции:';
											|en = 'Product group:'; fa = 'Product group:';
											|it = 'Группа продукции:';
											|pl = 'Grupa produkcji:';
											|tr = 'Grup imal edilen ürünler:'", DefaultLanguageCode) + Chars.NBSp
											+ String(CatalogObject.ProductsGroup);
		
		PartsOfName.Add(PresentationOfProductGroup);
	EndIf;	
	
	If CatalogObject.SaleOfAnotherCompanyInventory Then
		PartsOfName.Add(NStr("vi = 'Hàng tồn kho trong doanh nghiệp khác';
							|ru = 'Запасы другой организации';
							|en = 'Other company''s inventory'; fa = 'موجودی شرکت دیگر';
							|it = 'Scorte di un''altra azienda';
							|pl = 'Zapasy innej firmy';
							|tr = 'Diğer iş yerlerinin stokları'", DefaultLanguageCode));
	EndIf;
	If CatalogObject.SubjectToExcise Then
		PartsOfName.Add(NStr("vi = 'Chịu thuế TTĐB theo bộ phận:';
							|ru = 'Облагается акцизом по подразделению:';
							|en = 'It is subject to excise by business unit:'; fa = 'It is subject to excise by business unit:';
							|it = 'It is subject to excise by business unit:';
							|pl = 'It is subject to excise by business unit:';
							|tr = 'Departman bazında tüketim vergisine tabidir:'", DefaultLanguageCode)
									+ Chars.NBSp + String(CatalogObject.BusinessUnitProduction));
	EndIf;
	Return StrConcat(PartsOfName, "; ");

EndFunction

Procedure CheckDuplicates(CatalogObject)
	
	If CatalogObject.AdditionalProperties.Property("DonTCheckDuplicates")
		Or CatalogObject.IsDuplicate Then // with this property, we write mutable elements in the RIB
		
		Return;
		
	EndIf;
	
	BeginTransaction();
	
	Try
		Block = New DataLock;
		
		LockItem = Block.Add("Catalog.InventoryKinds");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("Organization",CatalogObject.Organization);
		LockItem.SetValue("InventoryType",CatalogObject.InventoryType);
		LockItem.SetValue("VATTaxation",CatalogObject.VATTaxation);
		LockItem.SetValue("GoodsOwner",CatalogObject.GoodsOwner);
		LockItem.SetValue("Terms",CatalogObject.Terms);
		LockItem.SetValue("Currency",CatalogObject.Currency);
		LockItem.SetValue("SaleOfAnotherCompanyInventory",CatalogObject.SaleOfAnotherCompanyInventory);
		LockItem.SetValue("InventoryOwnerAttributeOfCompanyGoodsOwner",CatalogObject.InventoryOwnerAttributeOfCompanyGoodsOwner);
		LockItem.SetValue("GoodsTransferMethod",CatalogObject.GoodsTransferMethod);
		LockItem.SetValue("NotUsedVendor",CatalogObject.NotUsedVendor);
		LockItem.SetValue("NotUsedPurpose",CatalogObject.NotUsedPurpose);
		LockItem.SetValue("NotUsedBusinessUnit",CatalogObject.NotUsedBusinessUnit);
		LockItem.SetValue("NotUsedManager",CatalogObject.NotUsedManager);
		LockItem.SetValue("NotUsedSalesOpportunity",CatalogObject.NotUsedSalesOpportunity);
		LockItem.SetValue("FinancialAccountingGroup",CatalogObject.FinancialAccountingGroup);
		LockItem.SetValue("Counterparty",CatalogObject.Counterparty);
		LockItem.SetValue("Contract",CatalogObject.Contract);
		LockItem.SetValue("NotUsedAssignment",CatalogObject.NotUsedAssignment);
		LockItem.SetValue("ProductsGroup",CatalogObject.ProductsGroup);
		LockItem.SetValue("PriceKind",CatalogObject.PriceKind);
		LockItem.SetValue("BusinessUnitProduction",CatalogObject.BusinessUnitProduction);
		LockItem.SetValue("SubjectToExcise",CatalogObject.SubjectToExcise);
		
		Block.Lock();
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	InventoryKinds.Ref AS Ref
		|FROM
		|	Catalog.InventoryKinds AS InventoryKinds
		|WHERE
		|	InventoryKinds.Organization = &Organization
		|	AND InventoryKinds.InventoryType = &InventoryType
		|	AND InventoryKinds.VATTaxation = &VATTaxation
		|	AND InventoryKinds.GoodsOwner = &GoodsOwner
		|	AND InventoryKinds.Terms = &Terms
		|	AND InventoryKinds.Currency = &Currency
		|	AND InventoryKinds.SaleOfAnotherCompanyInventory = &SaleOfAnotherCompanyInventory
		|	AND InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner = &InventoryOwnerAttributeOfCompanyGoodsOwner
		|	AND InventoryKinds.GoodsTransferMethod = &GoodsTransferMethod
		|	AND InventoryKinds.NotUsedVendor = &NotUsedVendor
		|	AND InventoryKinds.NotUsedPurpose = &NotUsedPurpose
		|	AND InventoryKinds.NotUsedBusinessUnit = &NotUsedBusinessUnit
		|	AND InventoryKinds.NotUsedManager = &NotUsedManager
		|	AND InventoryKinds.NotUsedSalesOpportunity = &NotUsedSalesOpportunity
		|	AND InventoryKinds.FinancialAccountingGroup = &FinancialAccountingGroup
		|	AND InventoryKinds.Counterparty = &Counterparty
		|	AND InventoryKinds.Contract = &Contract
		|	AND InventoryKinds.NotUsedAssignment = &NotUsedAssignment
		|	AND InventoryKinds.ProductsGroup = &ProductsGroup
		|	AND InventoryKinds.PriceKind = &PriceKind
		|	AND InventoryKinds.Obsolete1 = &Obsolete1
		|	AND InventoryKinds.BusinessUnitProduction = &BusinessUnitProduction
		|	AND InventoryKinds.SubjectToExcise = &SubjectToExcise
		|	AND NOT InventoryKinds.IsDuplicate
		|	AND InventoryKinds.Ref <> &Ref";
		
		Query.SetParameter("Organization", CatalogObject.Organization);
		Query.SetParameter("InventoryType", CatalogObject.InventoryType);
		Query.SetParameter("VATTaxation", CatalogObject.VATTaxation);
		Query.SetParameter("GoodsOwner", CatalogObject.GoodsOwner);
		Query.SetParameter("Terms", CatalogObject.Terms);
		Query.SetParameter("Currency", CatalogObject.Currency);
		Query.SetParameter("SaleOfAnotherCompanyInventory", CatalogObject.SaleOfAnotherCompanyInventory);
		Query.SetParameter("InventoryOwnerAttributeOfCompanyGoodsOwner", CatalogObject.InventoryOwnerAttributeOfCompanyGoodsOwner);
		Query.SetParameter("GoodsTransferMethod", CatalogObject.GoodsTransferMethod);
		Query.SetParameter("NotUsedVendor", CatalogObject.NotUsedVendor);
		Query.SetParameter("NotUsedPurpose", CatalogObject.NotUsedPurpose);
		Query.SetParameter("NotUsedBusinessUnit", CatalogObject.NotUsedBusinessUnit);
		Query.SetParameter("NotUsedManager", CatalogObject.NotUsedManager);
		Query.SetParameter("NotUsedSalesOpportunity", CatalogObject.NotUsedSalesOpportunity);
		Query.SetParameter("FinancialAccountingGroup", CatalogObject.FinancialAccountingGroup);
		Query.SetParameter("Counterparty", CatalogObject.Counterparty);
		Query.SetParameter("Contract", CatalogObject.Contract);
		Query.SetParameter("NotUsedAssignment", CatalogObject.NotUsedAssignment);
		Query.SetParameter("ProductsGroup", CatalogObject.ProductsGroup);
		Query.SetParameter("PriceKind", CatalogObject.PriceKind);
		Query.SetParameter("Obsolete1", CatalogObject.Obsolete1);
		Query.SetParameter("Ref", CatalogObject.Ref);
		Query.SetParameter("BusinessUnitProduction", CatalogObject.BusinessUnitProduction);
		Query.SetParameter("SubjectToExcise", CatalogObject.SubjectToExcise);
		
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then // there are no duplicates
			CommitTransaction();
			
			Return;
		EndIf;
		
		IsMasterNode1 = ExchangePlans.MasterNode() = Undefined;
		
		// Duplicates can only be formed with RIB, other situations are erroneous.
		// The types of stocks that are created or loaded from the main node are considered correct,
		// the rest are always marked as a double.
		If DataExchange.Load Then
			If IsMasterNode1 Then // uploaded from a subordinate node are considered duplicates.
				CatalogObject.IsDuplicate = True;
				CatalogObject.AdditionalProperties.Insert("DonTCheckDuplicates", True);
				CatalogObject.Write();
			Else
				// an entry is being made in the subordinate node.
				// The data that came from the main node is considered correct,
				// the existing ones are marked as duplicates.
				Selection = QueryResult.Select();
				
				While Selection.Next() Do
					DuplicateStockView = Selection.Ref.GetObject();
					DuplicateStockView.IsDuplicate = True;
					DuplicateStockView.DataExchange.Load = True;
					DuplicateStockView.AdditionalProperties.Insert("DonTCheckDuplicates", True);
					DuplicateStockView.Write();
				EndDo;
			EndIf;
		Else
			MessageText = NStr("vi = 'Việc ghi lại phần tử mới của danh mục ""Dạng vật tư"" tạo ra các phần tử trùng lặp!';
								|ru = 'При записи нового элемента справочника ""Виды запасов"" образуются дубли!';
								|en = 'Duplicates are created when saving a new item to the ""Inventory owner attributes"" catalog!'; fa = 'Duplicates are created when saving a new item to the ""Inventory owner attributes"" catalog!';
								|it = 'Durante la registrazione di un nuovo elemento della directory ""Tipi di scorte"" vengono generati i duplicati!';
								|pl = 'Podczas zapisu nowego elementu katalogu ""Виды запасов"" powstają duplikaty!';
								|tr = '""Stok türleri"" kataloğunun yeni bir öğesini kaydederken, kopyalar oluşuyor!'");
			
			Raise MessageText;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		EventName = NStr("vi = 'Ghi Dạng hàng tồn kho';
						|ru = 'Запись Видов запасов';
						|en = 'Save Inventory owner attributes'; fa = 'Save Inventory owner attributes';
						|it = 'Запись Видов запасов';
						|pl = 'Zapis Rodzajów zapasów';
						|tr = 'Stok türleri kaydı'", Common.DefaultLanguageCode());
		
		MessageText = NStr("vi = 'Không thể ghi lại danh mục Dạng vật tư do nguyên nhân: %Cause%';
							|ru = 'Не удалось записать справочник Виды запасов по причине: %Cause%';
							|en = 'Cannot save catalog ""Inventory owner attributes"". Reason: %Cause%'; fa = 'Cannot save catalog ""Inventory owner attributes"". Reason: %Cause%';
							|it = 'Impossibile registrare la directory Tipi di scorte a causa di: %Cause%';
							|pl = 'Nie udało się zapisać katalogu Rodzaje zapasów z powodu: %Cause%';
							|tr = '%Cause% nedeniyle stok türleri kataloğu kaydedilemedi'");
		MessageText = StrReplace(MessageText, "%Cause%", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(
			EventName,
			EventLogLevel.Error,
			Metadata.Catalogs.InventoryKinds,
			,
			MessageText);
		
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
