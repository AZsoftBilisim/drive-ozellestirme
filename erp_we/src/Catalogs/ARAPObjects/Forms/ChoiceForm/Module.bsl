
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not AccessRight("Read", Metadata.Catalogs.CounterpartyContracts)
		Or Not AccessRight("Read", Metadata.Catalogs.IntercompanyContracts)
		Or Not AccessRight("Read", Metadata.Catalogs.Partners)
		Or Not AccessRight("Read", Metadata.Catalogs.Counterparties)
		Or Not AccessRight("Read", Metadata.Catalogs.LinesOfBusiness) Then
		Text = NStr("vi = 'Không đủ quyền để mở biểu mẫu chọn đối tượng hạch toán.';
					|ru = 'Недостаточно прав для открытия формы выбора объекта расчетов.';
					|en = 'Insufficient rights to open the choice form of an AR/AP object.'; fa = 'Insufficient rights to open the choice form of an AR/AP object.';
					|it = 'Недостаточно прав для открытия формы выбора объекта расчетов.';
					|pl = 'Insufficient rights to open the choice form of an AR/AP object.';
					|tr = 'Alacak/Borç nesnesi seçim formunu açmak için yetki eksik.'");
		Common.MessageToUser(Text,,,,Cancel);
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	GroupOfHideServiceItems = CommonClientServer.CreateFilterItemGroup(
		APARObjectList.Filter.Items,
		NStr("vi = 'Ẩn các mục dịch vụ';
			|ru = 'Скрывать служебные';
			|en = 'Hide internal AR/AP objects'; fa = 'Hide internal AR/AP objects';
			|it = 'Скрывать служебные';
			|pl = 'Hide internal AR/AP objects';
			|tr = 'Özel olanları gizle'"),
		DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.AddCompositionItem(
		GroupOfHideServiceItems,
		"OnlyBalance",
		DataCompositionComparisonType.Equal,
		False,,
		True,
		DataCompositionSettingsItemViewMode.Normal);
	
	CommonClientServer.AddCompositionItem(
		GroupOfHideServiceItems,
		"IsInternal",
		DataCompositionComparisonType.Equal,
		False,,
		True,
		DataCompositionSettingsItemViewMode.Normal);
	
	APARObjectList.Parameters.SetParameterValue("SelectingThePaymentBasis", Parameters.SelectingThePaymentBasis);
	APARObjectList.Parameters.SetParameterValue("ChoosingAdvancePayment", Parameters.ChoosingAdvancePayment);
	OBEntry = Parameters.OBEntry;
	BusinessTransactionOfEnteringBalances = Parameters.BusinessOperation;
	If Parameters.OBEntry Then
		FilterValues = Common.CopyRecursive(Parameters.Filter);
	EndIf;
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("PaymentType_") Then
		TheseAreSettlementsWithCustomers = Parameters.Filter.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
		FilterStructure1 = ARAPAccountingClientServer.SelectionDataSelectionStructure();
		FillPropertyValues(FilterStructure1, Parameters.Filter);
		FilterStructure1.RecordBranches = Parameters.RecordBranches;
		PaymentBasisList.QueryText = TextOfRequestForPaymentGrounds(TheseAreSettlementsWithCustomers, FilterStructure1, 0);
		ListOfContractsOfCounterparties.QueryText = TextOfRequestForPaymentGrounds(TheseAreSettlementsWithCustomers, FilterStructure1, 1);
		ListOfContractsBetweenOrganizations.QueryText = TextOfRequestForPaymentGrounds(TheseAreSettlementsWithCustomers, FilterStructure1, 2);
		CommonClientServer.SetDynamicListFilterItem(
				APARObjectList,
				"PaymentType_",
				Parameters.Filter.PaymentType_,
				DataCompositionComparisonType.InList,
				,
				True);
		ListOfContractsTypes = ?(TheseAreSettlementsWithCustomers, 
		                         ARAPAccountingClientServer.TypesOfContractsWithClient(),
		                         ARAPAccountingClientServer.TypesOfContractsWithSupplier());
		ListOfContractsOfCounterparties.Parameters.SetParameterValue("ContractTypes", ListOfContractsTypes.UnloadValues());
	Else
		WithoutFilterByPaymentType = True;
	EndIf;
	
	APARObjectList.Parameters.SetParameterValue("WithoutFilterByPaymentType", WithoutFilterByPaymentType);
	
	If Parameters.SelectingThePaymentBasis Then
		Title = ?(TheseAreSettlementsWithCustomers,
			NStr("vi = 'Chọn cơ sở thanh toán của khách hàng';
				|ru = 'Выбор основания платежа клиента';
				|en = 'Select customer payment purpose'; fa = 'Select customer payment purpose';
				|it = 'Выбор основания платежа клиента';
				|pl = 'Select customer payment purpose';
				|tr = 'Müşterinin ödeme esasının seçimi'"),
			NStr("vi = 'Chọn cơ sở thanh toán của nhà cung cấp';
				|ru = 'Выбор основания платежа поставщика';
				|en = 'Select vendor payment purpose'; fa = 'Select vendor payment purpose';
				|it = 'Выбор основания платежа поставщика';
				|pl = 'Select vendor payment purpose';
				|tr = 'Tedarikçinin ödeme esasının seçilmesi'"));
	ElsIf WithoutFilterByPaymentType Then
		Title = NStr("vi = 'Chọn đối tượng hạch toán';
					|ru = 'Выбор объекта расчетов';
					|en = 'Select AR/AP object'; fa = 'Select AR/AP object';
					|it = 'Выбор объекта расчетов';
					|pl = 'Select AR/AP object';
					|tr = 'Alacak/Borç nesnesi seçimi'");
	Else
		Title = ?(TheseAreSettlementsWithCustomers,
			NStr("vi = 'Sự lựa chọn của đối tượng thanh toán với khách hàng';
				|ru = 'Выбор объекта расчетов с клиентом';
				|en = 'Select customer AR/AP object'; fa = 'Select customer AR/AP object';
				|it = 'Выбор объекта расчетов с клиентом';
				|pl = 'Select customer AR/AP object';
				|tr = 'Müşteri ile uzlaşma nesnesinin seçimi'"),
			NStr("vi = 'Chọn một đối tượng giải quyết với một nhà cung cấp';
				|ru = 'Выбор объекта расчетов с поставщиком';
				|en = 'Select vendor AR/AP object'; fa = 'Select vendor AR/AP object';
				|it = 'Выбор объекта расчетов с поставщиком';
				|pl = 'Select vendor AR/AP object';
				|tr = 'Tedarikçi ile yapılacak anlaşmaların konusunun seçimi'"));
	EndIf;
	
	NumberOfSelections = 0;
	If Parameters.Property("Filter") And Parameters.Filter.Property("Partner") And ValueIsFilled(Parameters.Filter.Partner) Then
		PartnerList = New ValueList;
		PartnersAndCounterparties.FillInListOfPartnersWithParents(Parameters.Filter.Partner, PartnerList);
		
		If Parameters.Filter.Partner = Catalogs.Partners.OurEnterprise Then
			TheseAreSettlementsBetweenOrganizations = True;
		EndIf;
		
		APARObjectList.Parameters.SetParameterValue("Partner", PartnerList);
		APARObjectList.Parameters.SetParameterValue("ForAllPartners", False);
		If Parameters.SelectingThePaymentBasis Then
			PaymentBasisList.Parameters.SetParameterValue("Partner", PartnerList);
			PaymentBasisList.Parameters.SetParameterValue("ForAllPartners", False);
			ListOfContractsOfCounterparties.Parameters.SetParameterValue("Partner", PartnerList);
			ListOfContractsOfCounterparties.Parameters.SetParameterValue("ForAllPartners", False);
		EndIf;
			
		Items.FilterPartner.Title = Parameters.Filter.Partner;
		NumberOfSelections = NumberOfSelections + 1;
	Else
		Items.FilterPartner.Visible = False;
		Items.TitlePartner.Visible = False;
		APARObjectList.Parameters.SetParameterValue("Partner", Undefined);
		APARObjectList.Parameters.SetParameterValue("ForAllPartners", True);
		PaymentBasisList.Parameters.SetParameterValue("Partner", Undefined);
		PaymentBasisList.Parameters.SetParameterValue("ForAllPartners", True);
		ListOfContractsOfCounterparties.Parameters.SetParameterValue("Partner", Undefined);
		ListOfContractsOfCounterparties.Parameters.SetParameterValue("ForAllPartners", True);
	EndIf;
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("Counterparty") Then
		If GetFunctionalOption("UsePartnersAsCounterparties") Then
			If TypeOf(Parameters.Filter.Counterparty) = Type("CatalogRef.Counterparties") Then
				If ValueIsFilled(Parameters.Filter.Counterparty) Then
					CounterpartySPartner = Common.ObjectAttributeValue(Parameters.Filter.Counterparty, "Partner");
				Else
					CounterpartySPartner = Undefined;
				EndIf;
				PartnerList = New ValueList;
				PartnersAndCounterparties.FillInListOfPartnersWithParents(CounterpartySPartner, PartnerList);
				Items.FilterPartner.Title = CounterpartySPartner;
				Items.FilterPartner.Visible = True;
				Items.TitlePartner.Visible = True;
				Parameters.Filter.Insert("Partner", PartnerList);
				NumberOfSelections = NumberOfSelections + 1;
			ElsIf TypeOf(Parameters.Filter.Counterparty) = Type("CatalogRef.Companies") Then
				Parameters.Filter.Insert("Partner", Catalogs.Partners.OurEnterprise);
				Items.FilterPartner.Title = Catalogs.Partners.OurEnterprise;
				Items.FilterPartner.Visible = True;
				Items.TitlePartner.Visible = True;
				NumberOfSelections = NumberOfSelections + 1;
			EndIf;
			Items.FilterCounterparty.Visible = False;
			Items.TitleCounterparty.Visible = False;
		Else
			Items.FilterCounterparty.Title = TitleText(Parameters.Filter.Counterparty);
			NumberOfSelections = NumberOfSelections + 1;
		EndIf;
		
		FilterCounterparty_ = Parameters.Filter.Counterparty;
		If TypeOf(Parameters.Filter.Counterparty) = Type("CatalogRef.Companies") Then
			Query = New Query(
			"
			|SELECT ALLOWED
			|	Companies.Ref AS Ref
			|FROM
			|	Catalog.Companies AS Companies
			|WHERE
			|	Companies.Ref IN (&Organization)
			|
			|UNION ALL
			|
			|SELECT
			|	Companies.Ref AS Ref
			|FROM
			|	Catalog.Companies AS Companies
			|WHERE
			|	Companies.ParentCompany IN (&Organization)
			|	AND Companies.TransactionsUsingParentCompanyAreAllowed
			|AUTOORDER");
			
			Query.SetParameter("Organization", Parameters.Filter.Counterparty);
			FilterCounterparty_ = Query.Execute().Unload().UnloadColumn("Ref");
			Items.FilterCounterparty.Title = TitleText(FilterCounterparty_);
			
		EndIf;
		
		APARObjectList.Parameters.SetParameterValue("Counterparty", FilterCounterparty_);
		APARObjectList.Parameters.SetParameterValue("ForAllCounterparties", False);
		
		If Parameters.SelectingThePaymentBasis Then
			PaymentBasisList.Parameters.SetParameterValue("Counterparty", FilterCounterparty_);
			PaymentBasisList.Parameters.SetParameterValue("ForAllCounterparties", False);
			ListOfContractsOfCounterparties.Parameters.SetParameterValue("Counterparty", FilterCounterparty_);
			ListOfContractsOfCounterparties.Parameters.SetParameterValue("ForAllCounterparties", False);
			ListOfContractsBetweenOrganizations.Parameters.SetParameterValue("Counterparty", FilterCounterparty_);
			ListOfContractsBetweenOrganizations.Parameters.SetParameterValue("ForAllCounterparties", False);
		EndIf;
		
	Else
		Items.FilterCounterparty.Visible = False;
		Items.TitleCounterparty.Visible = False;
		APARObjectList.Parameters.SetParameterValue("Counterparty", Undefined);
		APARObjectList.Parameters.SetParameterValue("ForAllCounterparties", True);
		PaymentBasisList.Parameters.SetParameterValue("Counterparty", Undefined);
		PaymentBasisList.Parameters.SetParameterValue("ForAllCounterparties", True);
		ListOfContractsOfCounterparties.Parameters.SetParameterValue("Counterparty", Undefined);
		ListOfContractsOfCounterparties.Parameters.SetParameterValue("ForAllCounterparties", True);
		ListOfContractsBetweenOrganizations.Parameters.SetParameterValue("Counterparty", Undefined);
		ListOfContractsBetweenOrganizations.Parameters.SetParameterValue("ForAllCounterparties", True);
	EndIf;
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("Organization") Then
		
		APARObjectList.Parameters.SetParameterValue("ByAllCompanies", False);
		FilterOrganization = Parameters.Filter.Organization;
		
		CentralizedContracts = New Array;
		ParentCompany      = Undefined;
		ThisIsParentOrganization   = False;
		
		If TypeOf(Parameters.Filter.Organization) <> Type("Array") And Parameters.RecordBranches Then
			
			ParentCompany      = Common.ObjectAttributeValue(Parameters.Filter.Organization, "ParentCompany");
			ThisIsParentOrganization   = Parameters.Filter.Organization = ParentCompany;
			
			If Not ThisIsParentOrganization Then
				
				Query = New Query(
					"SELECT ALLOWED DISTINCT
					|	BranchOffices_.Ref AS Ref
					|FROM
					|	Catalog.CounterpartyContracts.BranchOffices_ AS BranchOffices_
					|WHERE
					|	BranchOffices_.Organization = &Organization
					|");
				
				Query.SetParameter("Organization",Parameters.Filter.Organization);
				CentralizedContracts = Query.Execute().Unload().UnloadColumn("Ref");
				
			Else
				
				ParentCompany = Undefined;
				
			EndIf;
			
		EndIf;
		
		APARObjectList.Parameters.SetParameterValue("ThisIsParentOrganization",   ThisIsParentOrganization);
		APARObjectList.Parameters.SetParameterValue("ParentCompany",      ParentCompany);
		APARObjectList.Parameters.SetParameterValue("CentralizedContracts", CentralizedContracts);
		APARObjectList.Parameters.SetParameterValue("Organization",              Parameters.Filter.Organization);
		
		NumberOfSelections = NumberOfSelections + 1;
		
		Items.FilterOrganization.Title = TitleText(Parameters.Filter.Organization);
		
		If Parameters.SelectingThePaymentBasis Then
			PaymentBasisList.Parameters.SetParameterValue("ThisIsParentOrganization",   ThisIsParentOrganization);
			PaymentBasisList.Parameters.SetParameterValue("ParentCompany",      ParentCompany);
			PaymentBasisList.Parameters.SetParameterValue("CentralizedContracts", CentralizedContracts);
			PaymentBasisList.Parameters.SetParameterValue("Organization",              Parameters.Filter.Organization);
			
			ListOfContractsOfCounterparties.Parameters.SetParameterValue("ThisIsParentOrganization",   ThisIsParentOrganization);
			ListOfContractsOfCounterparties.Parameters.SetParameterValue("ParentCompany",      ParentCompany);
			ListOfContractsOfCounterparties.Parameters.SetParameterValue("CentralizedContracts", CentralizedContracts);
			ListOfContractsOfCounterparties.Parameters.SetParameterValue("Organization",              Parameters.Filter.Organization);
			
			ListOfContractsBetweenOrganizations.Parameters.SetParameterValue("Organization",              Parameters.Filter.Organization);
		EndIf;
		
	Else
		Items.FilterOrganization.Visible = False;
		Items.TitleOrganization.Visible = False;
		
		APARObjectList.Parameters.SetParameterValue("ByAllCompanies", True);
		APARObjectList.Parameters.SetParameterValue("Organization", Undefined);
		APARObjectList.Parameters.SetParameterValue("ThisIsParentOrganization", False);
		APARObjectList.Parameters.SetParameterValue("CentralizedContracts", New Array);
		APARObjectList.Parameters.SetParameterValue("ParentCompany", Undefined);
		
		PaymentBasisList.Parameters.SetParameterValue("Organization", Undefined);
		PaymentBasisList.Parameters.SetParameterValue("ThisIsParentOrganization", False);
		PaymentBasisList.Parameters.SetParameterValue("CentralizedContracts", New Array);
		PaymentBasisList.Parameters.SetParameterValue("ParentCompany", Undefined);
		
		ListOfContractsOfCounterparties.Parameters.SetParameterValue("Organization", Undefined);
		ListOfContractsOfCounterparties.Parameters.SetParameterValue("ThisIsParentOrganization", False);
		ListOfContractsOfCounterparties.Parameters.SetParameterValue("CentralizedContracts", New Array);
		ListOfContractsOfCounterparties.Parameters.SetParameterValue("ParentCompany", Undefined);
		
		ListOfContractsBetweenOrganizations.Parameters.SetParameterValue("Organization", Undefined);
	EndIf;
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("ARAPCurrency") And ValueIsFilled(Parameters.Filter.ARAPCurrency) Then
		Items.FilterARAPCurrency.Title = Parameters.Filter.ARAPCurrency;
		NumberOfSelections = NumberOfSelections + 1;
		CommonClientServer.SetDynamicListFilterItem(
			APARObjectList,
			"ARAPCurrency",
			Parameters.Filter.ARAPCurrency,
			DataCompositionComparisonType.Equal,
			,
			ValueIsFilled(Parameters.Filter.ARAPCurrency));
	Else
		Items.FilterARAPCurrency.Visible = False;
		Items.TitleSettlementCurrency.Visible = False;
	EndIf;
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("Ref")
		And TypeOf(Parameters.Filter.Ref) = Type("ValueList") Then
		CommonClientServer.SetDynamicListFilterItem(
			APARObjectList,
			"ARAPObject",
			Parameters.Filter.Ref,
			DataCompositionComparisonType.InList,
			,
			True);
	EndIf;
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("AdditionalFilters") Then
		
		For Each KeyAndValue In Parameters.Filter.AdditionalFilters Do
			
			If TypeOf(KeyAndValue.Value) = Type("Array") Then
				TypeOfSelectionComparison = DataCompositionComparisonType.InList;
			Else
				TypeOfSelectionComparison = DataCompositionComparisonType.Equal;
			EndIf;
			
			CommonClientServer.SetDynamicListFilterItem(
				APARObjectList,
				KeyAndValue.Key,
				KeyAndValue.Value,
				TypeOfSelectionComparison,
				,
				ValueIsFilled(KeyAndValue.Value));
				
			SelectionIsShown = ShowAdditionalSelectionOfCalculationObjects(APARObjectList, KeyAndValue);
			
			If SelectionIsShown Then
				NumberOfSelections = NumberOfSelections + 1;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If ValueIsFilled(Parameters.EditableDocument) Then
		ExcludedPaymentObject = ARAPObjectsServer.GetCalculationObjectFromLink(Parameters.EditableDocument,,
			?(Parameters.Filter.Property("PaymentType_"),Parameters.Filter.PaymentType_,Undefined));
		If ValueIsFilled(ExcludedPaymentObject) Then
			CommonClientServer.SetDynamicListFilterItem(
				APARObjectList,
				"ARAPObject",
				ExcludedPaymentObject,
				DataCompositionComparisonType.NotEqual,
				,
				ValueIsFilled(ExcludedPaymentObject));
		EndIf;
	EndIf;
	
	TypesOfBases_ = New Array;
	If Parameters.SelectingThePaymentBasis And Parameters.EditableDocument <> Undefined Then
		MetadataOfDocument = Parameters.EditableDocument.Metadata();
		If MetadataOfDocument <> Undefined Then
			TypeDescription = New TypeDescription;
			If TMCommonUse.ThereArePropsForPartOfObject("PaymentPurpose", MetadataOfDocument, "ARAPDetails") Then 
				TypeDescription = MetadataOfDocument.TabularSections.ARAPDetails.Attributes.PaymentPurpose.Type;
			ElsIf MetadataOfDocument.Attributes.Find("PaymentPurpose") <> Undefined Then
				TypeDescription = MetadataOfDocument.Attributes.PaymentPurpose.Type;
			EndIf;
			TypesOfBases_ = TypeDescription.Types();
		EndIf;
	EndIf;
	PaymentBasisList.Parameters.SetParameterValue("TypesOfBases_", TypesOfBases_);
	
	UseIntercompanyContracts = GetFunctionalOption("UseIntercompanyContracts");
	If Parameters.SelectingThePaymentBasis Then
		Items.GroupPages.CurrentPage = Items.PaymentBasisGroup;
		If Parameters.Property("CurrentValue") Then
			InitialBasisOfPayment = Parameters.CurrentValue;
		EndIf;
		Items.PaymentObjectGroup.Visible = False;
		Items.PaymentBasisGroupByType.CurrentPage = Items.DocumentsGroup;
		BaseSelectionSwitch = 0;
		If ValueIsFilled(InitialBasisOfPayment) Then
			If TypeOf(InitialBasisOfPayment) = Type("CatalogRef.CounterpartyContracts") Then
				Items.PaymentBasisGroupByType.CurrentPage = Items.GroupOfContractsOfCounterparties;
				BaseSelectionSwitch = 1;
			ElsIf TypeOf(InitialBasisOfPayment) = Type("CatalogRef.IntercompanyContracts") Then
				Items.PaymentBasisGroupByType.CurrentPage = Items.GroupContractsBetweenOrganizations;
				BaseSelectionSwitch = 1;
			EndIf;
		EndIf;
		If TheseAreSettlementsBetweenOrganizations And Not UseIntercompanyContracts Then
			Items.BaseSelectionSwitch.Visible = False;
			Items.PaymentBasisGroupByType.CurrentPage = Items.DocumentsGroup;
		EndIf;
	Else
		Items.GroupPages.CurrentPage = Items.PaymentObjectGroup;
		If Parameters.Property("CurrentValue") Then
			InitialObjectOfCalculations = Parameters.CurrentValue;
		EndIf;
		Items.PaymentBasisGroup.Visible = False;
	EndIf;
	
	SelectPaymentObjectsByCommission = Undefined;
	Parameters.Property("SelectPaymentObjectsByCommission", SelectPaymentObjectsByCommission);
	
	If Not SelectPaymentObjectsByCommission = Undefined Then
		
		PaymentViaCommissionAgent = True;
		
		If SelectPaymentObjectsByCommission.SelectObjectsOfSettlementsWithEndClient Then
			
			APARObjectList.Parameters.SetParameterValue("SelectObjectsOfSettlementsWithEndClient", True);
			APARObjectList.Parameters.SetParameterValue("SelectObjectsOfSettlementsWithCommissionAgent", False);
			APARObjectList.Parameters.SetParameterValue("ContractWithCommissionAgent",
				SelectPaymentObjectsByCommission.ContractWithCommissionAgent);
			APARObjectList.Parameters.SetParameterValue("CustomerCounterparty",
				SelectPaymentObjectsByCommission.Counterparty);
			APARObjectList.Parameters.SetParameterValue("CustomerPartner",
				SelectPaymentObjectsByCommission.Partner);
				
			Items.HeadingCommissionSales.Title = NStr("vi = 'Với khách hàng cuối';
														|ru = 'C конечным клиентом';
														|en = 'With end customer'; fa = 'With end customer';
														|it = 'Con cliente finale';
														|pl = 'Z nabywcą końcowym';
														|tr = 'Son müşteri ile'");
			Items.SelectionOfCommissionContracts.Title = StrTemplate(
					NStr("vi = '""%1"" theo hợp đồng với người nhận ký gửi ""%2""';
						|ru = '""%1"" по договору с комиссионером ""%2""';
						|en = '""%1"" by the contract with consignee ""%2""'; fa = '""%1"" by the contract with consignee ""%2""';
						|it = '""%1"" per accordo con il commissionario ""%2""';
						|pl = '""%1"" według kontraktu z komisantem ""%2""';
						|tr = '""%2"" konsinye ile ""%1"" sözleşmesine göre'"), 
						SelectPaymentObjectsByCommission.Counterparty,
						SelectPaymentObjectsByCommission.ContractWithCommissionAgent);
			
			Items.HeadingCommissionSales.Visible = True;
			Items.SelectionOfCommissionContracts.Visible = True;
			NumberOfSelections = NumberOfSelections + 1;
			
		Else
			
			APARObjectList.Parameters.SetParameterValue("SelectObjectsOfSettlementsWithEndClient", False);
			APARObjectList.Parameters.SetParameterValue("SelectObjectsOfSettlementsWithCommissionAgent", True);
			APARObjectList.Parameters.SetParameterValue("ContractWithCommissionAgent", Undefined);
			APARObjectList.Parameters.SetParameterValue("CustomerCounterparty", Undefined);
			APARObjectList.Parameters.SetParameterValue("CustomerPartner", Undefined);
			
			Items.SelectionOfCommissionContracts.Title = NStr("vi = 'Với người nhận bán ký gửi';
																|ru = 'С комиссионером';
																|en = 'With consignee'; fa = 'With consignee';
																|it = 'Con il commissionario';
																|pl = 'Z komisantem';
																|tr = 'Konsinye ile'");
			
			Items.HeadingCommissionSales.Visible = True;
			Items.SelectionOfCommissionContracts.Visible = True;
			NumberOfSelections = NumberOfSelections + 1;
			
		EndIf;
		
	Else
			
		Items.HeadingCommissionSales.Visible = False;
		Items.SelectionOfCommissionContracts.Visible = False;
		APARObjectList.Parameters.SetParameterValue("SelectObjectsOfSettlementsWithEndClient", False);
		APARObjectList.Parameters.SetParameterValue("SelectObjectsOfSettlementsWithCommissionAgent", False);
		APARObjectList.Parameters.SetParameterValue("ContractWithCommissionAgent", Undefined);
		APARObjectList.Parameters.SetParameterValue("CustomerCounterparty", Undefined);
		APARObjectList.Parameters.SetParameterValue("CustomerPartner", Undefined);
		
	EndIf;
	
	If NumberOfSelections > 0 Then
		Items.GroupPresetSelections.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đặt lọc: %1';
																											|ru = 'Установлено отборов: %1';
																											|en = 'Active filters: %1'; fa = 'Active filters: %1';
																											|it = 'Selezioni impostate: %1';
																											|pl = 'Ustawiono filtrów: %1';
																											|tr = 'Filtreler ayarlandı: %1'"), NumberOfSelections);
	Else
		Items.GroupPresetSelections.Visible = False;
	EndIf;
	
	If Parameters.Property("SelectAccountsReceivable") Then
		Items.CalculationObjectsAmountBalance.Title = ?(Parameters.SelectAccountsReceivable, NStr("vi = 'Công nợ phải thu';
																									|ru = 'Дебиторская задолженность';
																									|en = 'Accounts receivable'; fa = 'حساب‌های دریافتنی';
																									|it = 'Crediti';
																									|pl = 'Wierzytelność';
																									|tr = 'Alacaklar'"), NStr("vi = 'Công nợ phải trả';
																																		|ru = 'Кредиторская задолженность';
																																		|en = 'Accounts payable'; fa = 'حساب‌های پرداختنی';
																																		|it = 'Debiti';
																																		|pl = 'Zobowiązania';
																																		|tr = 'Borçlar'"));
		APARObjectList.Parameters.SetParameterValue("SelectAccountsReceivable", Parameters.SelectAccountsReceivable);
	Else
		Items.CalculationObjectsAmountBalance.Title = NStr("vi = 'Công nợ phải thu';
															|ru = 'Дебиторская задолженность';
															|en = 'Accounts receivable'; fa = 'حساب‌های دریافتنی';
															|it = 'Crediti';
															|pl = 'Wierzytelność';
															|tr = 'Alacaklar'");
		APARObjectList.Parameters.SetParameterValue("SelectAccountsReceivable", True);
	EndIf;
	
	If Parameters.Property("ReturnStructure") Then
		ReturnStructure = Parameters.ReturnStructure;
	EndIf;
	If Parameters.OBEntry Then
		AvailableTypeList = Documents.OBEntryARAP.ListOfAvailableTypesOfARAPObject(
			Parameters.BusinessOperation,
			TheseAreSettlementsBetweenOrganizations,
			FilterValues.Property("Partner") And FilterValues.Partner = PredefinedValue("Catalog.Partners.RetailCustomer"));
		Items.FormCreateObject.Visible = AvailableTypeList.Count() > 0;
	Else
		Items.FormCreateObject.Visible = False;
	EndIf;

	UseMultipleCurrencies             = GetFunctionalOption("UseMultipleCurrencies");

	TMCommonUseClientServer.SetFormItemProperty(Items, "PaymentObjectsCurrency", "Visible", UseMultipleCurrencies);
	TMCommonUseClientServer.SetFormItemProperty(Items, "PaymentGroundsCurrency", "Visible", UseMultipleCurrencies);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	WhenOpenedOnServer();
	If Items.ARAPObjects.CurrentRow <> Undefined 
		And Items.ARAPObjects.CurrentData.Property("ARAPObjectType")
		And Items.ARAPObjects.CurrentData.ARAPObjectType <> FIlter_By_Type Then
		FIlter_By_Type = PredefinedValue("Enum.ARAPObjectTypes.EmptyRef");
	EndIf;
	
	If BusinessTransactionOfEnteringBalances = PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerBonuses")
	 Or BusinessTransactionOfEnteringBalances = PredefinedValue("Enum.BusinessTransactions.OBEntryVendorBonuses") Then
		
		FIlter_By_Type = PredefinedValue("Enum.ARAPObjectTypes.Invoice");
		Items.FIlter_By_Type.Visible = False;
		
	EndIf;
	
	SetSelectionByType();
	
EndProcedure

&AtServerNoContext
Procedure ARAPObjectsOnGetDataAtServer(TagName, Settings, Rows)
	
	If Rows.Count() = 0 Then
		Return;
	EndIf;
	
	ValueTableClient = New ValueTable;
	ValueTableClient.Columns.Add("Ref", New TypeDescription("CatalogRef.ARAPObjects"));
	
	TableOfSupplierValues = New ValueTable;
	TableOfSupplierValues.Columns.Add("Ref", New TypeDescription("CatalogRef.ARAPObjects"));
	
	For Each String In Rows Do
		
		If String.Value.Data.SumBalance <> 0 Or String.Value.Data.AmountDue <> 0 Then
			Continue;
		EndIf;
		
		If String.Value.Data.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
			FillPropertyValues(ValueTableClient.Add(),String.Value.Data,"Ref");
		ElsIf String.Value.Data.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting Then
			FillPropertyValues(TableOfSupplierValues.Add(),String.Value.Data,"Ref");
		EndIf;
	EndDo;
	
	ArrayOfTexts = New Array;
	
	If ValueTableClient.Count() > 0 Then
		QueryText = "
		|SELECT ALLOWED
		|	Calculations.ARAPObject AS Ref,
		|	CASE 
		|		WHEN &SelectAccountsReceivable AND Calculations.SumBalance < 0
		|			OR NOT &SelectAccountsReceivable AND Calculations.SumBalance > 0
		|				THEN 0
		|		WHEN Calculations.SumBalance < 0 
		|				THEN - Calculations.SumBalance
		|		ELSE Calculations.SumBalance
		|	END AS SumBalance,
		|	CASE 
		|		WHEN Calculations.AmountDueBalance> 0
		|			THEN Calculations.AmountDueBalance
		|		ELSE 0
		|	END AS AmountDue,
		|	Calculations.BeingPaidBalance AS BeingPaid
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.Balance(,ARAPObject IN (SELECT Ref FROM TTTableOfValuesClient)) AS Calculations";
		ArrayOfTexts.Add(QueryText);
	EndIf;
	
	If TableOfSupplierValues.Count() > 0 Then
		QueryText = "
		|SELECT ALLOWED
		|	Calculations.ARAPObject AS Ref,
		|	CASE 
		|		WHEN &SelectAccountsReceivable AND Calculations.SumBalance < 0
		|			OR NOT &SelectAccountsReceivable AND Calculations.SumBalance > 0
		|				THEN 0
		|		WHEN Calculations.SumBalance < 0 
		|				THEN - Calculations.SumBalance
		|		ELSE Calculations.SumBalance
		|	END AS SumBalance,
		|	CASE 
		|		WHEN - Calculations.AmountDueBalance > 0
		|			THEN - Calculations.AmountDueBalance
		|		ELSE 0
		|	END AS AmountDue,
		|	- Calculations.BeingPaidBalance AS BeingPaid
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Balance(,ARAPObject IN (SELECT Ref FROM TTTableOfValuesSupplier)) AS Calculations";
		If ArrayOfTexts.Count() > 0 Then 
			QueryText = StrReplace(QueryText, "SELECT ALLOWED", "SELECT"); //@Query-part-1 @Query-part-2
		EndIf;
		ArrayOfTexts.Add(QueryText);
	EndIf;
	
	If ArrayOfTexts.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "
		|SELECT
		|	ValueTable.Ref AS Ref
		|INTO TTTableOfValuesClient
		|FROM 
		|	&ValueTableClient AS ValueTable
		|;
		|SELECT
		|	ValueTable.Ref AS Ref
		|INTO TTTableOfValuesSupplier
		|FROM 
		|	&TableOfSupplierValues AS ValueTable
		|;"
		+ StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin());
	
	Query.SetParameter("SelectAccountsReceivable", 
		Settings.DataParameters.Items.Find("SelectAccountsReceivable").Value);
	Query.SetParameter("ValueTableClient", ValueTableClient);
	Query.SetParameter("TableOfSupplierValues", TableOfSupplierValues);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		ListLine = Rows[Selection.Ref];
		FillPropertyValues(ListLine.Data,Selection,"AmountDue, SumBalance, BeingPaid");
	EndDo;
	
EndProcedure

&AtClient
Procedure PaymentBaseObjectsBeforeRowChange(Item, Cancel)
	Cancel = True;
	OpenObject(0);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OnlyWithBalanceOnChange(Item)
	UpdateTextOfRequestForCalculationObjects();
EndProcedure

&AtClient
Procedure FIlter_By_TypeOnChange(Item)
	SetSelectionByType();
EndProcedure

&AtClient
Procedure BaseSelectionSwitchOnChange(Item)
	If BaseSelectionSwitch = 1 Then
		If TheseAreSettlementsBetweenOrganizations Then
			Items.PaymentBasisGroupByType.CurrentPage = Items.GroupContractsBetweenOrganizations;
		Else
			Items.PaymentBasisGroupByType.CurrentPage = Items.GroupOfContractsOfCounterparties;
		EndIf;
	Else
		Items.PaymentBasisGroupByType.CurrentPage = Items.DocumentsGroup;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenObject(Command)
	
	If Items.GroupPages.CurrentPage = Items.PaymentObjectGroup Then
		TableRow = Items.ARAPObjects.CurrentData;
		If TableRow <> Undefined 
			And Not CommonClientServer.HasAttributeOrObjectProperty(TableRow, "RowGroup")
			And ValueIsFilled(TableRow.ARAPObject) Then
			ShowValue(Undefined, TableRow.ARAPObject);
		EndIf;
	ElsIf Items.GroupPages.CurrentPage = Items.PaymentBasisGroup Then 
		If Items.PaymentBasisGroupByType.CurrentPage = Items.DocumentsGroup Then
			TableRow = Items.PaymentBaseObjects.CurrentData;
		ElsIf Items.PaymentBasisGroupByType.CurrentPage = Items.GroupOfContractsOfCounterparties Then 
			TableRow = Items.ListOfContractsOfCounterparties.CurrentData;
		Else
			TableRow = Items.ListOfContractsBetweenOrganizations.CurrentData;
		EndIf;
		If TableRow <> Undefined 
			And Not CommonClientServer.HasAttributeOrObjectProperty(TableRow, "RowGroup")
			And ValueIsFilled(TableRow.PaymentPurpose) Then
			ShowValue(Undefined, TableRow.PaymentPurpose);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectDocument(Command)
	
	If Items.GroupPages.CurrentPage = Items.PaymentObjectGroup Then
		TableRow = Items.ARAPObjects.CurrentData;
	ElsIf Items.PaymentBasisGroupByType.CurrentPage = Items.DocumentsGroup Then
		TableRow = Items.PaymentBaseObjects.CurrentData;
	ElsIf Items.PaymentBasisGroupByType.CurrentPage = Items.GroupOfContractsOfCounterparties Then
		TableRow = Items.ListOfContractsOfCounterparties.CurrentData;
	Else
		TableRow = Items.ListOfContractsBetweenOrganizations.CurrentData;
	EndIf;
	
	If TableRow <> Undefined Then
		If CommonClientServer.HasAttributeOrObjectProperty(TableRow, "RowGroup") Then
			ShowMessageBox(,
							NStr("vi = 'Hãy chọn phần tử, không phải nhóm.
							|Để mở nhóm, hãy sử dụng ""Ctrl"" và mũi tên lên/xuống
							|hoặc phím ""+"" và ""-"" trên bàn phím.';
							|ru = 'Выберите элемент, а не группу.
							|Для раскрытия групп используйте ""Ctrl"" и стрелки вниз/вверх
							|или клавиши ""+"" и ""-"" на дополнительной клавиатуре.';
							|en = 'Select an item, not a group.
							|To expand groups, use ""Ctrl"" and the up/down arrows
							|or ""+"" and ""-"" keys on the additional keyboard.'; fa = 'Select an item, not a group.
							|To expand groups, use ""Ctrl"" and the up/down arrows
							|or ""+"" and ""-"" keys on the additional keyboard.';
							|it = 'Selezionare elemento, non un gruppo.
							|Per rivelare i gruppi utilizzare ""Ctrl"" e le frecce su/giù
							|o le chiavi ""+"" e ""-"" sulla tastiera aggiuntiva.';
							|pl = 'Wybierz element, a nie grupę.
							|W celu otwarcia grupy używaj ""Ctrl"" i strzałki do dołu/do góry
							|lub klawisze ""+"" i ""-"" na dodatkowej klawiaturze.';
							|tr = 'Grup değil, öğe seç.
							|Grupları genişletmek için ek klavyedeki ""Ctrl"" ve yukarı/aşağı okları
							|veya ""+"" ve ""-"" tuşlarını kullan.'"));
		Else
			If ReturnStructure Then
				SelectionResult = ?(Items.GroupPages.CurrentPage = Items.PaymentObjectGroup,
					ResultOfSelectingARAPObject(TableRow),
					ResultOfChoosingPaymentBasis(TableRow));
			Else
				SelectionResult = TableRow.ARAPObject;
			EndIf;
			NotifyChoice(SelectionResult);
		EndIf;
	Else
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateObject(Command)
	OpeningParameters = New Structure;
	OpeningParameters.Insert("BusinessOperation", BusinessTransactionOfEnteringBalances);
	OpeningParameters.Insert(
		"TheseAreSettlementsBetweenOrganizations", 
		FilterValues.Property("Partner") 
			And FilterValues.Partner = PredefinedValue("Catalog.Partners.OurEnterprise"));
	OpeningParameters.Insert(
		"ThisIsRetailBuyer", 
		FilterValues.Property("Partner") 
			And FilterValues.Partner = PredefinedValue("Catalog.Partners.RetailCustomer"));
	CallbackDescription = New CallbackDescription("ARAPObjectCreationProcessingOfTypeSelection", ThisObject);
	OpenForm("Document.OBEntryARAP.Form.TypeChoiceForm", OpeningParameters, ThisObject,,,, CallbackDescription);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPObjectsNumber.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPObjectsDate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPObjectsRefType.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CalculationObjectsAmount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentObjectsCurrency.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CalculationObjectsAmountBalance.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettlementObjectsSettlementCurrency.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPObjectsOrganization.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPObjectsPartner.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPObjectsContract.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPObjectsCounterparty.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPObjectsIncomingDocumentNumber.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPObjectsIncomingDocumentDate.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LinkToTheCalculationObject.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("APARObjectList.State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 1;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("APARObjectList.ARAPObjectType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ARAPObjectTypes.Contract;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPObjectsRefType.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("APARObjectList.RefType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Đối tượng không được chỉ định>';
													|ru = '<Объект не указан>';
													|en = '<Object is not specified>'; fa = '<Object is not specified>';
													|it = '<Oggetto non indicato>';
													|pl = '<Nie wskazano obiektu>';
													|tr = '<Nesne belirtilmedi>'"));
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisForm, "PaymentBasisList.Date", "PaymentBaseObjectsDate");
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisForm, "PaymentBasisList.IncomingDocumentDate", "PaymentGroundsDateOfTheIncomingDocument");

EndProcedure

&AtClient
Procedure ARAPObjectsSelection(Item, RowSelected, Field, StandardProcessing)
	TableRow = Items.ARAPObjects.CurrentData;
	If Not CommonClientServer.HasAttributeOrObjectProperty(TableRow, "RowGroup") Then
		If ReturnStructure Then
			SelectionResult = ResultOfSelectingARAPObject(TableRow);
		Else
			SelectionResult = TableRow.ARAPObject;
		EndIf;
		NotifyChoice(SelectionResult);
	EndIf;
EndProcedure

&AtClient
Procedure PaymentBaseObjectsSelection(Item, RowSelected, Field, StandardProcessing)
	TableRow = Items.PaymentBaseObjects.CurrentData;
	If Not CommonClientServer.HasAttributeOrObjectProperty(TableRow, "RowGroup") Then
		SelectionResult = ResultOfChoosingPaymentBasis(TableRow);
		NotifyChoice(SelectionResult);
	EndIf;
EndProcedure

&AtClient
Procedure ListOfContractsOfCounterpartiesSelection(Item, RowSelected, Field, StandardProcessing)
	TableRow = Items.ListOfContractsOfCounterparties.CurrentData;
	If Not CommonClientServer.HasAttributeOrObjectProperty(TableRow, "RowGroup") Then
		SelectionResult = ResultOfChoosingPaymentBasis(TableRow);
		NotifyChoice(SelectionResult);
	EndIf;
EndProcedure

&AtClient
Procedure ListOfContractsBetweenOrganizationsSelection(Item, RowSelected, Field, StandardProcessing)
	TableRow = Items.ListOfContractsBetweenOrganizations.CurrentData;
	If Not CommonClientServer.HasAttributeOrObjectProperty(TableRow, "RowGroup") Then
		SelectionResult = ResultOfChoosingPaymentBasis(TableRow);
		NotifyChoice(SelectionResult);
	EndIf;
EndProcedure

&AtClient
Function ResultOfSelectingARAPObject(TableRow)
	
	SelectionResult = New Structure;
	SelectionResult.Insert("Organization", TableRow.Organization);
	SelectionResult.Insert("Partner", TableRow.Partner);
	SelectionResult.Insert("Counterparty", TableRow.Counterparty);
	SelectionResult.Insert("Contract", TableRow.Contract);
	SelectionResult.Insert("PaymentPurpose", TableRow.PaymentPurpose);
	SelectionResult.Insert("LineOfBusiness", TableRow.LineOfBusiness);
	SelectionResult.Insert("ItIsAllowedToWorkWithSubsidiaryPartners", TableRow.ItIsAllowedToWorkWithSubsidiaryPartners);
	SelectionResult.Insert("Date", TableRow.Date);
	SelectionResult.Insert("Number", TableRow.Number);
	SelectionResult.Insert("OrderAmount", TableRow.Sum);
	SelectionResult.Insert("ARAPObject", TableRow.ARAPObject);
	SelectionResult.Insert("ARAPCurrency", TableRow.ARAPCurrency);
	SelectionResult.Insert("CentralizedContract", TableRow.CentralizedContract);
	SelectionResult.Insert("FeeViaEndCustomers", TableRow.FeeViaEndCustomers);
	SelectionResult.Insert("Object", TableRow.Object);
	SelectionResult.Insert("PaymentID", TableRow.PaymentID);
	
	SelectionResult.Insert("PaymentAmount", PaymentAmount);
	SelectionResult.Insert("TheseAreSettlementsWithCustomers", TheseAreSettlementsWithCustomers);
	SelectionResult.Insert("AmountARAP", 0);
	SelectionResult.Insert("VATRate", PredefinedValue("Catalog.VATRates.EmptyRef"));
	SelectionResult.Insert("VATAmount", 0);
	SelectionResult.Insert("MaturityDate", Date(1, 1, 1));
	SelectionResult.Insert("PaymentDate", Date(1, 1, 1));
	
	Return SelectionResult;
	
EndFunction

&AtClient
Function ResultOfChoosingPaymentBasis(TableRow)
	
	SelectionResult = New Structure;
	SelectionResult.Insert("PaymentPurpose", TableRow.PaymentPurpose);
	SelectionResult.Insert("Contract", TableRow.Contract);
	
	Return SelectionResult;
	
EndFunction

&AtServer
Function TitleText(Var_Items, Var_AttributeName = "Description")
	
	If TypeOf(Var_Items) = Type("Array") Then
		Attributes = Common.ObjectsAttributeValue(Var_Items, Var_AttributeName);
		Names = New Array;
		For Each Item In Var_Items Do
			Names.Add(Attributes[Item]);
		EndDo;
		TitleText = StrConcat(Names, Chars.LF);
	Else
		TitleText = Var_Items;
	EndIf;
	
	Return TitleText;
	
EndFunction

// The Query Text for selecting the payment basis from the dynamic list.
// 
// Parameters:
//  TheseAreSettlementsWithClient  - Boolean - Flag containing True
//  	if "The selection structure.Type of settlements = Transfers.Types of settlements by partners.Calculation by client".
//  FilterStructure1 - See ARAPAccountingClientServer.SelectionDataSelectionStructure.
//  BasisType - Number - Possible values: 0 Document, 1 Contract with a counterparty, 2 Contract between organizations.
//  	The source of the records is responsible for the tiblitsa.
//
// Returns:
//  String - query text.
//
&AtServerNoContext
Function TextOfRequestForPaymentGrounds(TheseAreSettlementsWithClient, FilterStructure1, BasisType)
	
	QueryText = "";
	
	QueryConditions = New Array;
	QueryConditions.Add("TRUE");
	
	If BasisType = 0 Then
		QueryText = "
		|SELECT
		|	DocumentsRegistry.Ref AS PaymentPurpose,
		|	DocumentsRegistry.RefType AS BasisType,
		|	DocumentsRegistry.Partner AS Partner,
		|	DocumentsRegistry.Organization AS Organization,
		|	DocumentsRegistry.Counterparty.Key AS Counterparty,
		|	DocumentsRegistry.Contract AS Contract,
		|	DocumentsRegistry.IBDocumentNumber AS Number,
		|	DocumentsRegistry.IBDocumentDate AS Date,
		|	DocumentsRegistry.SourceDocumentDate AS IncomingDocumentDate,
		|	DocumentsRegistry.SourceDocumentNumber AS IncomingDocumentNumber,
		|	DocumentsRegistry.SourceDocumentName AS SourceDocumentName,
		|	DocumentsRegistry.Sum AS Sum,
		|	DocumentsRegistry.Currency AS Currency
		|FROM
		|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|
		|LEFT JOIN
		|	Catalog.CounterpartyContracts AS Contracts
		|ON
		|	DocumentsRegistry.Contract = Contracts.Ref
		|WHERE
		|	(DocumentsRegistry.Organization IN (&Organization)
		|		OR NOT &ThisIsParentOrganization
		|			AND DocumentsRegistry.Contract IN (&CentralizedContracts)
		|			AND (DocumentsRegistry.Organization = &ParentCompany
		|				OR ISNULL(Contracts.TransferAndOffsetOfPaymentsBetweenBranchOfficesIsAllowed, FALSE))
		|		OR &ThisIsParentOrganization
		|			AND DocumentsRegistry.Organization.ParentCompany IN (&Organization)
		|			AND DocumentsRegistry.Organization.TransactionsUsingParentCompanyAreAllowed)
		|
		|	AND &DynamicConditions
		|";
		
		If ValueIsFilled(FilterStructure1.Counterparty) Then
			QueryConditions.Add("(DocumentsRegistry.Counterparty.Key IN (&Counterparty) OR &ForAllCounterparties)");
		EndIf;
		
		QueryConditions.Add("VALUETYPE(DocumentsRegistry.Ref) IN(&TypesOfBases_)");
		
	ElsIf BasisType = 1 Then
		QueryText = "
		|SELECT
		|	Contracts.Ref AS PaymentPurpose,
		|	Contracts.Partner AS Partner,
		|	Contracts.Organization AS Organization,
		|	Contracts.Counterparty AS Counterparty,
		|	Contracts.Ref AS Contract,
		|	Contracts.LineOfBusiness AS LineOfBusiness,
		|	Contracts.PaymentID AS PaymentID,
		|	Contracts.Number AS Number,
		|	Contracts.Date AS Date,
		|	Contracts.Sum AS Sum,
		|	Contracts.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Catalog.CounterpartyContracts AS Contracts
		|WHERE
		|	(Contracts.Organization IN (&Organization)
		|		OR NOT &ThisIsParentOrganization
		|			AND Contracts.Ref IN (&CentralizedContracts)
		|			AND (Contracts.Organization = &ParentCompany
		|				OR Contracts.TransferAndOffsetOfPaymentsBetweenBranchOfficesIsAllowed)
		|		OR &ThisIsParentOrganization
		|			AND Contracts.Organization.ParentCompany IN (&Organization)
		|			AND Contracts.Organization.TransactionsUsingParentCompanyAreAllowed)
		|	AND Contracts.ContractType IN (&ContractTypes)
		|
		|	AND &DynamicConditions
		|";
		
		If ValueIsFilled(FilterStructure1.Counterparty) Then
			QueryConditions.Add("(Contracts.Counterparty IN (&Counterparty) OR &ForAllCounterparties)");
		EndIf;
		
	ElsIf BasisType = 2 Then
		QueryText = "
		|SELECT
		|	Contracts.Ref AS PaymentPurpose,
		|	VALUE(Catalog.Partners.OurEnterprise) AS Partner,
		|	Contracts.Organization AS Organization,
		|	Contracts.CompanyRecipient AS Counterparty,
		|	Contracts.Ref AS Contract,
		|	Contracts.LineOfBusiness AS LineOfBusiness,
		|	Contracts.PaymentID AS PaymentID,
		|	Contracts.Number AS Number,
		|	Contracts.Date AS Date,
		|	Contracts.Sum AS Sum,
		|	Contracts.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Catalog.IntercompanyContracts AS Contracts
		|WHERE
		|	(Contracts.CompanyRecipient = &Organization)
		|
		|	AND &DynamicConditions
		|";
		
		If ValueIsFilled(FilterStructure1.Counterparty) Then
			QueryConditions.Add(?(TheseAreSettlementsWithClient,
				"(Contracts.CompanyRecipient IN (&Counterparty) OR &ForAllCounterparties)",
				"(Contracts.Organization IN (&Counterparty) OR &ForAllCounterparties)"));
		EndIf;
	EndIf;
	
	QueryText = StrReplace(QueryText, "&DynamicConditions", StrConcat(QueryConditions, " And "));
	
	Return QueryText;
	
EndFunction

&AtServer
Procedure WhenOpenedOnServer()
	
	UpdateTextOfRequestForCalculationObjects();
	
	If ValueIsFilled(InitialBasisOfPayment)
		Or ValueIsFilled(InitialObjectOfCalculations) Then
		SetCurrentRow();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateTextOfRequestForCalculationObjects()
	
	ArrayOfConditions = New Array;
	ArrayOfConditions.Add("NOT &SelectingThePaymentBasis");
	
	If Not OnlyWithBalance Or WithoutFilterByPaymentType Then
		
		QueryText = "
		|SELECT 
		|	ARAPObjects.Ref AS ARAPObject, 
		|	ARAPObjects.Ref AS Ref,
		|	ARAPObjects.DeletionMark, 
		|	ARAPObjects.Description, 
		|	ARAPObjects.Object, 
		|	ARAPObjects.Object AS PaymentPurpose,
		|	ARAPObjects.PaymentType_,
		|	ARAPObjects.ARAPObjectType,
		|	ARAPObjects.RefType, 
		|	ARAPObjects.FinancialAccountingGroup, 
		|	ARAPObjects.Manager, 
		|	ARAPObjects.Department, 
		|	ARAPObjects.PaymentID, 
		|	ARAPObjects.Number, 
		|	ARAPObjects.Date, 
		|	ARAPObjects.IncomingDocumentNumber, 
		|	ARAPObjects.IncomingDocumentDate, 
		|	ARAPObjects.SourceDocumentName, 
		|	ARAPObjects.Sum, 
		|	ARAPObjects.Currency, 
		|	ARAPObjects.State,
		|	ARAPObjects.Partner,
		|	ARAPObjects.Organization, 
		|	ARAPObjects.Counterparty, 
		|	ARAPObjects.Contract, 
		|	ARAPObjects.LineOfBusiness, 
		|	ISNULL(Contracts.ItIsAllowedToWorkWithSubsidiaryPartners, FALSE) AS ItIsAllowedToWorkWithSubsidiaryPartners,
		|	ISNULL(Contracts.CentralizedContract, FALSE) AS CentralizedContract, 
		|	ISNULL(Contracts.ContractWithCommissionAgent.ConductARAPAccountingThroughEndCustomers, FALSE) AS FeeViaEndCustomers,
		|	ARAPObjects.ForeignCurrencyTransaction, 
		|	ARAPObjects.ARAPCurrency,
		|	&SelectAccountsReceivable AS SelectAccountsReceivable,
		|	ARAPObjects.OnlyBalance   AS OnlyBalance,
		|	ARAPObjects.IsInternal AS IsInternal,
		|	ARAPObjects.OperationWithSelfEmployedPerson AS OperationWithSelfEmployedPerson,
		|	0 AS SumBalance,
		|	0 AS AmountDue,
		|	0 AS BeingPaid
		|FROM
		|	Catalog.ARAPObjects AS ARAPObjects
		|		LEFT JOIN Catalog.CounterpartyContracts AS Contracts
		|			ON ARAPObjects.Contract = Contracts.Ref
		|WHERE
		|	&QueryConditions
		|";
		
	Else
		
		ArrayOfConditions.Add("(Balance.SumBalance > 0 OR Balance.AmountDue > 0)");
		
		If TheseAreSettlementsWithCustomers Then
			TextBalance = "
				|SELECT
				|	Calculations.ARAPObject AS ARAPObject,
				|	CASE 
				|		WHEN &SelectAccountsReceivable AND Calculations.SumBalance < 0
				|			OR NOT &SelectAccountsReceivable AND Calculations.SumBalance > 0
				|				THEN 0
				|		WHEN Calculations.SumBalance < 0 
				|				THEN - Calculations.SumBalance
				|		ELSE Calculations.SumBalance
				|	END AS SumBalance,
				|	CASE 
				|		WHEN Calculations.AmountDueBalance> 0
				|			THEN Calculations.AmountDueBalance
				|		ELSE 0
				|	END AS AmountDue,
				|	Calculations.BeingPaidBalance AS BeingPaid
				|INTO TTBalance
				|FROM
				|	AccumulationRegister.CustomersARAPAccounting.Balance() AS Calculations
				|INDEX BY
				|	ARAPObject
				|;";
		Else
			TextBalance = "
				|SELECT
				|	Calculations.ARAPObject AS ARAPObject,
				|	CASE 
				|		WHEN &SelectAccountsReceivable AND Calculations.SumBalance < 0
				|			OR NOT &SelectAccountsReceivable AND Calculations.SumBalance > 0
				|				THEN 0
				|		WHEN Calculations.SumBalance < 0 
				|				THEN - Calculations.SumBalance
				|		ELSE Calculations.SumBalance
				|	END AS SumBalance,
				|	CASE 
				|		WHEN -Calculations.AmountDueBalance > 0
				|			THEN -Calculations.AmountDueBalance
				|		ELSE 0
				|	END AS AmountDue,
				|	-Calculations.BeingPaidBalance AS BeingPaid
				|INTO TTBalance
				|FROM
				|	AccumulationRegister.VendorsARAPAccounting.Balance() AS Calculations
				|INDEX BY
				|	ARAPObject
				|;";
		EndIf;
		
		QueryText = TextBalance+ "
		|SELECT 
		|	ARAPObjects.Ref AS ARAPObject, 
		|	ARAPObjects.Ref AS Ref,
		|	ARAPObjects.DeletionMark, 
		|	ARAPObjects.Description, 
		|	ARAPObjects.Object, 
		|	ARAPObjects.Object AS PaymentPurpose,
		|	ARAPObjects.PaymentType_,
		|	ARAPObjects.ARAPObjectType,
		|	ARAPObjects.RefType, 
		|	ARAPObjects.FinancialAccountingGroup, 
		|	ARAPObjects.Manager, 
		|	ARAPObjects.Department, 
		|	ARAPObjects.PaymentID, 
		|	ARAPObjects.Number, 
		|	ARAPObjects.Date, 
		|	ARAPObjects.IncomingDocumentNumber, 
		|	ARAPObjects.IncomingDocumentDate, 
		|	ARAPObjects.SourceDocumentName, 
		|	ARAPObjects.Sum, 
		|	ARAPObjects.Currency, 
		|	ARAPObjects.State,
		|	ARAPObjects.Partner,
		|	ARAPObjects.Organization, 
		|	ARAPObjects.Counterparty, 
		|	ARAPObjects.Contract, 
		|	ARAPObjects.LineOfBusiness, 
		|	ISNULL(Contracts.ItIsAllowedToWorkWithSubsidiaryPartners, FALSE) AS ItIsAllowedToWorkWithSubsidiaryPartners,
		|	ISNULL(Contracts.CentralizedContract, FALSE) AS CentralizedContract,
		|	ISNULL(Contracts.ContractWithCommissionAgent.ConductARAPAccountingThroughEndCustomers, FALSE) AS FeeViaEndCustomers,
		|	ARAPObjects.ForeignCurrencyTransaction, 
		|	ARAPObjects.ARAPCurrency,
		|	&SelectAccountsReceivable AS SelectAccountsReceivable,
		|	ARAPObjects.OnlyBalance   AS OnlyBalance,
		|	ARAPObjects.IsInternal AS IsInternal,
		|	ARAPObjects.OperationWithSelfEmployedPerson AS OperationWithSelfEmployedPerson,
		|	Balance.SumBalance AS SumBalance,
		|	Balance.AmountDue AS AmountDue,
		|	Balance.BeingPaid AS BeingPaid
		|FROM
		|	Catalog.ARAPObjects AS ARAPObjects
		|		INNER JOIN TTBalance AS Balance 
		|			ON Balance.ARAPObject = ARAPObjects.Ref
		|		LEFT JOIN Catalog.CounterpartyContracts AS Contracts
		|			ON ARAPObjects.Contract = Contracts.Ref
		|WHERE
		|	&QueryConditions
		|";
		
	EndIf;
	
	ArrayOfConditions.Add("(ARAPObjects.Organization IN (&Organization) 
		|	OR NOT &ThisIsParentOrganization 
		|		AND ARAPObjects.Contract IN (&CentralizedContracts)
		|		AND (ARAPObjects.Organization = &ParentCompany
		|			OR Contracts.TransferAndOffsetOfPaymentsBetweenBranchOfficesIsAllowed)
		|	OR &ThisIsParentOrganization
		|		AND ARAPObjects.Organization.ParentCompany IN (&Organization)
		|		AND ARAPObjects.Organization.TransactionsUsingParentCompanyAreAllowed
		|	OR &ByAllCompanies)");
	
	If PaymentViaCommissionAgent Then
		ArrayOfConditions.Add("(Contracts.ContractType = VALUE(Enum.ContractTypes.WithConsignee) 
			|	AND Contracts.ConsignmentSales25
			|	OR NOT &SelectObjectsOfSettlementsWithCommissionAgent)");
		ArrayOfConditions.Add("(Contracts.ContractWithCommissionAgent = &ContractWithCommissionAgent 
			|	AND Contracts.Counterparty = &CustomerCounterparty 
			|	AND Contracts.Partner = &CustomerPartner 
			|	OR NOT &SelectObjectsOfSettlementsWithEndClient)");
	EndIf;
	
	If OBEntry Then
		
		If BusinessTransactionOfEnteringBalances = PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerBonuses") Then
			
			ArrayOfConditions.Add("(CAST(ARAPObjects.Object AS Document.SourceDocument).SourceDocumentType = VALUE(Enum.SourceDocumentTypes.CustomerBonusCertificate))");
			
		ElsIf BusinessTransactionOfEnteringBalances = PredefinedValue("Enum.BusinessTransactions.OBEntryVendorBonuses") Then
			
			ArrayOfConditions.Add("(CAST(ARAPObjects.Object AS Document.SourceDocument).SourceDocumentType = VALUE(Enum.SourceDocumentTypes.VendorBonusCertificate))");
			
		Else
			
			ArrayOfConditions.Add("((ARAPObjects.ARAPObjectType <> VALUE(Enum.ARAPObjectTypes.Invoice)
				|		OR ARAPObjects.Object REFS Document.SourceDocument
				|			AND CAST(ARAPObjects.Object AS Document.SourceDocument).SourceDocumentType <> VALUE(Enum.SourceDocumentTypes.CustomerBonusCertificate)
				|			AND CAST(ARAPObjects.Object AS Document.SourceDocument).SourceDocumentType <> VALUE(Enum.SourceDocumentTypes.VendorBonusCertificate)
				|			AND NOT &ChoosingAdvancePayment)
				|	AND (ARAPObjects.ARAPObjectType <> VALUE(Enum.ARAPObjectTypes.PaymentReturn)
				|		OR (ARAPObjects.Object REFS Document.SourceDocument
				|			OR ARAPObjects.Object REFS Catalog.GiftCertificates
				|			OR ARAPObjects.Object REFS Document.RequestForReturnOfGoodsFromCustomer)
				|			AND &ChoosingAdvancePayment))");
			
		EndIf;
		
		ArrayOfConditions.Add("(ARAPObjects.Partner IN (&Partner)
			|	OR &ForAllPartners
			|	OR ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Contract)
			|	AND ISNULL(Contracts.ContractWithCommissionAgent.ConductARAPAccountingThroughEndCustomers, FALSE)
			|	AND Contracts.Partner IN(&Partner))");
		ArrayOfConditions.Add("(ARAPObjects.Counterparty IN (&Counterparty)
			|	OR &ForAllCounterparties
			|	OR ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Contract)
			|	AND ISNULL(Contracts.ContractWithCommissionAgent.ConductARAPAccountingThroughEndCustomers, FALSE)
			|	AND Contracts.Counterparty IN(&Counterparty))");
		ArrayOfConditions.Add("NOT (ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Contract)
			|	AND ISNULL(Contracts.ContractWithCommissionAgent.ConductARAPAccountingThroughEndCustomers, FALSE)
			|	AND Contracts.CommissionAgentPartner IN (&Partner)
			|	AND Contracts.CounterpartyCommissionAgent IN(&Counterparty))");
	Else
		ArrayOfConditions.Add("(ARAPObjects.Partner IN (&Partner) OR &ForAllPartners)");
		ArrayOfConditions.Add("(ARAPObjects.Counterparty IN (&Counterparty) OR &ForAllCounterparties)");
		ArrayOfConditions.Add("(NOT (ARAPObjects.Object REFS Catalog.GiftCertificates) 
		                       |	OR &WithoutFilterByPaymentType)");
	EndIf;
	
	QueryCondition = StrConcat(
		ArrayOfConditions,
		"
		|AND ");
	
	APARObjectList.QueryText = StrReplace(QueryText, "&QueryConditions", QueryCondition);
	Items.ARAPObjects.Refresh();
	
EndProcedure

&AtClient
Procedure SetSelectionByType()
	
	If ValueIsFilled(FIlter_By_Type) Then
		CommonClientServer.SetDynamicListFilterItem(
			APARObjectList,
			"ARAPObjectType",
			FIlter_By_Type,
			DataCompositionComparisonType.Equal,,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
	Else
		CommonClientServer.DeleteDynamicListFilterGroupItems(
			APARObjectList,
			"ARAPObjectType");
	EndIf;
	Items.ARAPObjects.Refresh();
	
EndProcedure

&AtClient
Procedure ARAPObjectCreationProcessingOfTypeSelection(Result, AdditionalParameters)Export 
	If Result <> Undefined Then
		FillingValues = CommonClient.CopyRecursive(FilterValues);
		FillingValues.Insert("ConductComplaintARAP", True);
		If BusinessTransactionOfEnteringBalances = PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentFromCustomer") Then
			FillingValues.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.SaleToCustomer"));
			FillingValues.Insert("ThisIsClaimToVendor", False);
		ElsIf BusinessTransactionOfEnteringBalances = PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerBonuses") Then
			FillingValues.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.RecordCustomerBonusRebates"));
			FillingValues.Insert("ThisIsClaimToVendor", False);
		ElsIf BusinessTransactionOfEnteringBalances = PredefinedValue("Enum.BusinessTransactions.OBEntryUnmatchedPrepaymentToVendor") Then
			FillingValues.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier"));
			FillingValues.Insert("ThisIsClaimToVendor", True);
		ElsIf BusinessTransactionOfEnteringBalances = PredefinedValue("Enum.BusinessTransactions.OBEntryCustomerAccountsReceivable") Then
			FillingValues.Insert("ThisIsClaimToVendor", False);
			FillingValues.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.SaleToCustomer"));
		ElsIf BusinessTransactionOfEnteringBalances = PredefinedValue("Enum.BusinessTransactions.OBEntryVendorAccountsPayable") Then
			FillingValues.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier"));
			FillingValues.Insert("ThisIsClaimToVendor", True);
		ElsIf BusinessTransactionOfEnteringBalances = PredefinedValue("Enum.BusinessTransactions.OBEntryVendorBonuses") Then
			FillingValues.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.RecordVendorBonusRebate"));
			FillingValues.Insert("ThisIsClaimToVendor", False);
		EndIf;
		If TypeOf(Result) = Type("Structure") Then
			MetadataObjectName = Result.MetadataObjectName;
			FillingValues.Insert("SourceDocumentType", Result.SourceDocumentType);
		Else
			MetadataObjectName = Result;
		EndIf;
		ParametersStructure = New Structure("FillingValues", FillingValues);
		OpenForm(MetadataObjectName + ".ObjectForm", ParametersStructure, ThisObject);
	EndIf;
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If Items.GroupPages.CurrentPage = Items.PaymentObjectGroup Then
		Items.ARAPObjects.Refresh();
	ElsIf Items.GroupPages.CurrentPage = Items.PaymentBasisGroup Then 
		If Items.PaymentBasisGroupByType.CurrentPage = Items.DocumentsGroup Then
			Items.PaymentBaseObjects.Refresh();
		ElsIf Items.PaymentBasisGroupByType.CurrentPage = Items.GroupOfContractsOfCounterparties Then 
			Items.ListOfContractsOfCounterparties.Refresh();
		Else
			Items.ListOfContractsBetweenOrganizations.Refresh();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function ShowAdditionalSelectionOfCalculationObjects(List, Filter)

	FilterAvailableFields = List.SettingsComposer.Settings.Filter.FilterAvailableFields.Items;
	DescriptionOfSelectionField = Undefined; // Undefined, DataCompositionAvailableField
	
	FieldElements = StrSplit(Filter.Key, ".");
	IndexOf = 0;
	PartsOfSelectionField = New Array;
	
	GetDescriptionOfSelectionField(DescriptionOfSelectionField, FilterAvailableFields, FieldElements, PartsOfSelectionField, IndexOf);
	
	If DescriptionOfSelectionField <> Undefined Then
		
		NameWithoutDot = StrReplace(Filter.Key, ".", "_");
		TitleName = StrTemplate("Title_%1", NameWithoutDot);
		FilterName = StrTemplate("Filter_%1", NameWithoutDot);
		
		NewItem = Items.Add(
			TitleName,
			Type("FormDecoration"),
			Items.AdditionalHeadersGroup);
		NewItem.Type = FormDecorationType.Label;
		
		NewItem = Items.Add(
			FilterName,
			Type("FormDecoration"),
			Items.AdditionalValuesGroup);
		NewItem.Type = FormDecorationType.Label;
		
		Items[TitleName].Title = StrTemplate("%1:", DescriptionOfSelectionField.Title);
		
		If TypeOf(Filter.Value) = Type("Array") Then
			
			ValueList = New Array;
			
			For Each ValueRow In Filter.Value Do
				
				If ValueIsFilled(ValueRow) Then
					ValueList.Add(ValueRow);
				Else
					Continue;
				EndIf;
				
			EndDo;
			
			Items[FilterName].Title = StrConcat(ValueList, ";");
			
		Else
			Items[FilterName].Title = Filter.Value;
		EndIf;
		
		Return True;
		
	Else
		Return False;
	EndIf;

EndFunction

// Gets a field description from the available selection fields.
// 
// Parameters:
//  DescriptionOfSelectionField - Undefined, DataCompositionAvailableField - Description of the field available for use.
//  FilterAvailableFields - DataCompositionAvailableFieldCollection - Collection of available fields for selection.
//  FieldElements - Array of String - Components of the selection key.
//  PartsOfSelectionField - Array of String - Part of the constituent parts of the selection key.
//  IndexOf - Number - Index of an element from the field elements.
&AtServer
Procedure GetDescriptionOfSelectionField(DescriptionOfSelectionField, FilterAvailableFields, FieldElements, PartsOfSelectionField, IndexOf)

	If IndexOf < FieldElements.Count() Then
		
		PartsOfSelectionField.Add(FieldElements[IndexOf]);
		Id = StrConcat(PartsOfSelectionField, ".");
		DescriptionOfSelectionField = FilterAvailableFields.Find(Id);
		
		If DescriptionOfSelectionField <> Undefined Then
			GetDescriptionOfSelectionField(DescriptionOfSelectionField, DescriptionOfSelectionField.Items, FieldElements, PartsOfSelectionField, IndexOf + 1);
		EndIf;
		
	EndIf;

EndProcedure

&AtServer
Procedure SetCurrentRow()
	
	If ValueIsFilled(InitialBasisOfPayment) Then
		If TypeOf(InitialBasisOfPayment) = Type("CatalogRef.CounterpartyContracts") Then
			Items.ListOfContractsOfCounterparties.CurrentRow = InitialBasisOfPayment;
		ElsIf TypeOf(InitialBasisOfPayment) = Type("CatalogRef.IntercompanyContracts") Then
			Items.ListOfContractsBetweenOrganizations.CurrentRow = InitialBasisOfPayment;
		Else
			Items.PaymentBaseObjects.CurrentRow = InformationRegisters.DocumentsRegistry.DocumentRecordingKey(InitialBasisOfPayment);
		EndIf;
	EndIf;
	If ValueIsFilled(InitialObjectOfCalculations) Then
		Items.ARAPObjects.CurrentRow = InitialObjectOfCalculations;
	EndIf;
	
EndProcedure

#EndRegion
