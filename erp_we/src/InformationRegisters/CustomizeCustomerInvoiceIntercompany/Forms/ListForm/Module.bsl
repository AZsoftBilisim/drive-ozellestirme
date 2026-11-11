
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Items.InventoryType.ChoiceList.Add(Enums.InventoryTypes.OwnGoods);
	If GetFunctionalOption("UsePurchaseCommission") Then
		Items.InventoryType.ChoiceList.Add(Enums.InventoryTypes.ConsignedGoods);
	EndIf;
	
	If GetFunctionalOption("UseCustodyDuringPurchase") Then
		Items.InventoryType.ChoiceList.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	EndIf;
	
	Items.InventoryType.Visible = Items.InventoryType.ChoiceList.Count() > 1;
	
	Organization         = Parameters.CompanyOwner;
	CompanyCustomer = Parameters.CompanyCustomer;
	
	FillInSettingsTable();
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Settings.Clear();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	FillInSettingsTable();
	
EndProcedure

&AtClient
Procedure CompanyCustomerOnChange(Item)
	
	FillInSettingsTable();
	
EndProcedure

&AtClient
Procedure InventoryTypeOnChange(Item)
	
	FillInSettingsTable();
	
EndProcedure

&AtClient
Procedure SettingsTable1Selection(Item, RowSelected, Field, StandardProcessing)
	
	Var TransferMethod;
	Var Currency;
	
	Position = 0;
	CharsCount = StrLen(Field.Name);
	For Cnt = 0 To CharsCount - 1 Do
		If StrFind("0123456789", Mid(Field.Name, CharsCount - Cnt, 1)) = 0 Then
			Position = CharsCount - Cnt + 1;
			ColumnIndex = Mid(Field.Name, Position);
			Break;
		EndIf;
	EndDo;
	
	ColumnIndex = Mid(Field.Name, Position);
	
	TableRow = Items.SettingsTable1.CurrentData;
	
	
	If TableRow.Property("TransferMethod" + ColumnIndex) Then
		
		NoTransferMethodRequired = PredefinedValue("Enum.GoodsTransferMethods.NotRequired");
		If TableRow["TransferMethod" + ColumnIndex] <> NoTransferMethodRequired Then
			
			KeyStructure1 = New Structure("CompanyOwner, CompanyCustomer, InventoryType");
			KeyStructure1.CompanyCustomer = TableRow["Seller" + ColumnIndex];
			KeyStructure1.CompanyOwner = TableRow.Organization;
			KeyStructure1.InventoryType = TableRow.InventoryType;
			
			RecordingFormParameters = New Structure;
			
			If TableRow["IsInRegister" + ColumnIndex] Then
				RecordingFormParameters.Insert("Key", RegisterRecordKey(KeyStructure1));
			Else
				KeyStructure1.Insert("GoodsTransferMethod", TableRow["TransferMethod" + ColumnIndex]);
				
				If Not ValueIsFilled(KeyStructure1.GoodsTransferMethod) Then
					KeyStructure1.GoodsTransferMethod = PredefinedValue("Enum.GoodsTransferMethods.NotTransferred");
				EndIf;
				
				RecordingFormParameters.Insert("FillingValues", KeyStructure1);
			EndIf;
			
			CallbackDescription = New CallbackDescription("SettingsTable1SelectionCompletion",
																	ThisObject,
																	New Structure("ColumnIndex, TableRow", ColumnIndex, TableRow));
			
			OpenForm("InformationRegister.CustomizeCustomerInvoiceIntercompany.RecordForm",
						RecordingFormParameters
						,
						,
						,
						,
						,
						CallbackDescription,
						FormWindowOpeningMode.LockOwnerWindow);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function RegisterRecordKey(KeyStructure1)
	
	Return InformationRegisters.CustomizeCustomerInvoiceIntercompany.CreateRecordKey(KeyStructure1);
	
EndFunction

&AtClient
Procedure SettingsTable1SelectionCompletion(Result, AdditionalParameters) Export
	
	ColumnIndex = AdditionalParameters.ColumnIndex;
	TableRow = AdditionalParameters.TableRow;
	
	If Result <> Undefined Then
		TableRow["TransferMethod" + ColumnIndex] = Result.GoodsTransferMethod;
		TableRow["Currency" + ColumnIndex] = Result.Currency;
		TableRow["Contract" + ColumnIndex] = Result.Contract;
		TableRow["PriceKind" + ColumnIndex] = Result.PriceKind;
		TableRow["IsInRegister" + ColumnIndex] = True;
	EndIf;

EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure AddConfigurationTreeLine(Selection, ComplianceOfOrganizations, Val OrganizationString)
	
	If Selection.RecordType() = QueryRecordType.GroupTotal Then
		
		If Selection.Level() = 1 Then
			
		 	OrganizationString = SettingsTable1.Add();
			FillPropertyValues(OrganizationString, Selection);
			
		EndIf;
		
		NextSelection = Selection.Select(QueryResultIteration.ByGroups);
		While NextSelection.Next() Do
			AddConfigurationTreeLine(NextSelection, ComplianceOfOrganizations, OrganizationString);
		EndDo;
		
	Else
		
		ColumnIndex = ComplianceOfOrganizations.Get(Selection.Seller);
		If OrganizationString <> Undefined
		 And ColumnIndex <> Undefined Then
			OrganizationString["Seller" + ColumnIndex] = Selection.Seller;
			OrganizationString["TransferMethod" + ColumnIndex] = Selection.GoodsTransferMethod;
			OrganizationString["Currency" + ColumnIndex] = Selection.Currency;
			OrganizationString["Contract" + ColumnIndex] = Selection.Contract;
			OrganizationString["PriceKind" + ColumnIndex] = Selection.PriceKind;
			OrganizationString["IsInRegister" + ColumnIndex] = Selection.IsInRegister;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInSettingsTable()
	
	Query = New Query("
	|SELECT ALLOWED
	|	Companies.Ref AS Organization,
	|	Companies.Description AS OrganizationPresentation
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.Ref <> &Organization
	|	AND (Companies.Ref = &CompanyCustomer
	|		OR &CompanyCustomer = UNDEFINED)
	|	AND NOT Companies.DeletionMark
	|	AND Companies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
	|	AND (NOT Companies.Predefined OR &UseManagementCompany)
	|
	|ORDER BY
	|	Companies.Description ASC
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	ISNULL(InventoryTypes.Ref, VALUE(Enum.InventoryTypes.EmptyRef)) AS InventoryType,
	|	Companies.Ref AS Organization,
	|	ISNULL(Sellers.Ref, VALUE(Catalog.Companies.EmptyRef)) AS Seller,
	|
	|	CASE WHEN Companies.Ref = Sellers.Ref
	|		OR Companies.ParentCompany = Sellers.Ref
	|		OR Companies.Ref = Sellers.ParentCompany
	|		OR (Companies.ParentCompany = Sellers.ParentCompany AND Companies.BranchOffice)
	|	THEN
	|		VALUE(Enum.GoodsTransferMethods.NotRequired)
	|	ELSE
	|		Setting.GoodsTransferMethod
	|	END AS GoodsTransferMethod,
	|
	|	(CASE WHEN &UseMultipleCurrencies THEN Setting.Currency
	|		ELSE VALUE(Catalog.Currencies.EmptyRef) END) AS Currency,
	|
	|	ISNULL(Setting.Contract, VALUE(Catalog.IntercompanyContracts.EmptyRef)) AS Contract,
	|	ISNULL(Setting.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef)) AS PriceKind,
	|	NOT Setting.CompanyOwner IS NULL AS IsInRegister
	|FROM
	|	Catalog.Companies AS Companies
	|	
	|	LEFT JOIN
	|		Enum.InventoryTypes AS InventoryTypes
	|	ON
	|		TRUE
	|		
	|	LEFT JOIN
	|		Catalog.Companies AS Sellers
	|	ON
	|		TRUE
	|		
	|	LEFT JOIN
	|		InformationRegister.CustomizeCustomerInvoiceIntercompany AS Setting
	|	ON
	|		Companies.Ref = Setting.CompanyOwner
	|		AND Sellers.Ref = Setting.CompanyCustomer
	|		AND InventoryTypes.Ref = Setting.InventoryType
	|		
	|WHERE
	|	NOT Companies.DeletionMark
	|	AND NOT Sellers.DeletionMark
	|	AND InventoryTypes.Ref IN (&InventoryTypes)
	|	AND (Companies.Ref = &Organization
	|		OR &Organization = UNDEFINED)
	|	AND (InventoryTypes.Ref = &InventoryType
	|		OR &InventoryType = UNDEFINED)
	|	AND Companies.Ref <> &CompanyCustomer
	|	AND Sellers.Ref <> &Organization
	|	AND (Sellers.Ref = &CompanyCustomer
	|		OR &CompanyCustomer = UNDEFINED)
	|	AND (NOT Companies.Predefined OR &UseManagementCompany)
	|	AND (NOT Sellers.Predefined OR &UseManagementCompany)
	|
	|ORDER BY
	|	Companies.Description ASC,
	|	InventoryType,
	|	Seller
	|
	|TOTALS BY
	|	Organization,
	|	InventoryType
	|");
	Query.SetParameter("Organization", ?(ValueIsFilled(Organization), Organization, Undefined));
	Query.SetParameter("CompanyCustomer", ?(ValueIsFilled(CompanyCustomer), CompanyCustomer, Undefined));
	Query.SetParameter("InventoryTypes", Items.InventoryType.ChoiceList.UnloadValues());
	Query.SetParameter("InventoryType", ?(ValueIsFilled(InventoryType), InventoryType, Undefined));
	Query.SetParameter("UseManagementCompany", GetFunctionalOption("UseManagementCompany"));
	Query.SetParameter("UseMultipleCurrencies", GetFunctionalOption("UseMultipleCurrencies"));
	ResultsArray = Query.ExecuteBatch();
	
	SetPrivilegedMode(True);
	
	QueryResultForOrganizations = ResultsArray[0]; // QueryResult
	QueryResultByInventoryType = ResultsArray[1]; // QueryResult
	
	AttributesToAddArray = New Array;
	ComplianceOfOrganizations = New Map;
	MatchingBankDetails = New Map;
	OrganizationIndex = 0;
	
	// Let's add columns to the settings table.
	SelectionByOrganization_ = QueryResultForOrganizations.Select();
	While SelectionByOrganization_.Next() Do
		
		If OrganizationIndex >= NumberOfColumnGroups Then
			NewAttribute = New FormAttribute(
				"TransferMethod" + OrganizationIndex,
				New TypeDescription("EnumRef.GoodsTransferMethods"),
				"SettingsTable1",
				SelectionByOrganization_.OrganizationPresentation);
			MatchingBankDetails.Insert(NewAttribute, OrganizationIndex);
			
			AttributesToAddArray.Add(NewAttribute);
			
			// Let's add a new column "Seller".
			NewPropsSeller = New FormAttribute(
				"Seller" + OrganizationIndex,
				New TypeDescription("CatalogRef.Companies"),
				"SettingsTable1");
			AttributesToAddArray.Add(NewPropsSeller);
			
			// Let's add a new column "Currency".
			NewPropsCurrency = New FormAttribute(
				"Currency" + OrganizationIndex,
				New TypeDescription("CatalogRef.Currencies"),
				"SettingsTable1");
			AttributesToAddArray.Add(NewPropsCurrency);
			MatchingBankDetails.Insert(NewPropsCurrency, OrganizationIndex);
			
			// Let's add a new column "Price type".
			NewPropsKindOfPrice = New FormAttribute(
				"PriceKind" + OrganizationIndex,
				New TypeDescription("CatalogRef.TypesOfPrices"),
				"SettingsTable1");
			AttributesToAddArray.Add(NewPropsKindOfPrice);
			MatchingBankDetails.Insert(NewPropsKindOfPrice, OrganizationIndex);
			
			// Let's add a new column "Contract".
			NewDetailsContract = New FormAttribute(
				"Contract" + OrganizationIndex,
				New TypeDescription("CatalogRef.IntercompanyContracts"),
				"SettingsTable1");
			AttributesToAddArray.Add(NewDetailsContract);
			MatchingBankDetails.Insert(NewDetailsContract, OrganizationIndex);
			
			// Let's add a new column "There is a register".
			NewPropsAreInRegister = New FormAttribute(
				"IsInRegister" + OrganizationIndex,
				New TypeDescription("Boolean"),
				"SettingsTable1");
			AttributesToAddArray.Add(NewPropsAreInRegister);
			MatchingBankDetails.Insert(NewPropsAreInRegister, OrganizationIndex);
		EndIf;
		
		ComplianceOfOrganizations.Insert(SelectionByOrganization_.Organization, OrganizationIndex);
		
		OrganizationIndex = OrganizationIndex + 1;
		
	EndDo;
	
	NumberOfOrganizations = ComplianceOfOrganizations.Count();
	
	If AttributesToAddArray.Count() > 0 Then
		ChangeAttributes(AttributesToAddArray);
	EndIf;
	
	// Let's add the form elements.
	For Each Attribute In AttributesToAddArray Do
		
		If StrFind(Attribute.Name, "IsInRegister") > 0
			Or StrFind(Attribute.Name, "Seller") > 0 Then
			Continue;
		EndIf;
		
		NumberOfGroup = MatchingBankDetails.Get(Attribute);
		If NumberOfGroup = Undefined Then
			NumberOfGroup = 99;
		EndIf;
		
		GroupName = "GroupSettingsTable" + NumberOfGroup;
		GroupItem1 = Items.Find(GroupName);
		If GroupItem1 = Undefined Then
			GroupItem1 = Items.Add(
				GroupName,
				Type("FormGroup"),
				Items[Attribute.Path]);
			GroupItem1.Group = ColumnsGroup.InCell;
		EndIf;
		
		TagName = Attribute.Path + Attribute.Name;
		Item = Items.Find(TagName);
		
		If Item = Undefined Then
			Item = Items.Add(
				TagName,
				Type("FormField"),
				GroupItem1);
			Item.Type = FormFieldType.InputField;
			Item.DataPath = Attribute.Path + "." + Attribute.Name;
			Item.ReadOnly = True;
			
			If StrFind(Attribute.Name, "TransferMethod") = 0 Then
				Item.TitleLocation = FormItemTitleLocation.None;
			EndIf;
			
			If StrFind(TagName, "Currency") > 0 Then
				Item.Width = 5;
			Else
				Item.Width = 10;
			EndIf;
		EndIf;
		
	EndDo;
	
	For Each KeyValue In ComplianceOfOrganizations Do
		Field = Items["SettingsTable1" + "TransferMethod" + Format(KeyValue.Value,"NZ=0; NG=0")]; // ConditionalAppearanceItem
		Field.Title = KeyValue.Key; 		
	EndDo;
	
	// Fill in the settings table.
	SettingsTable1.Clear();
	
	Selection = QueryResultByInventoryType.Select(QueryResultIteration.ByGroups);
	While Selection.Next() Do
		AddConfigurationTreeLine(
			Selection,
			ComplianceOfOrganizations,
			Undefined); // OrganizationString
	EndDo;

	NumberOfColumnGroupsPreviously = NumberOfColumnGroups;
	NumberOfColumnGroups = Max(NumberOfColumnGroups, NumberOfOrganizations);	
	
	For Cnt = 0 To NumberOfColumnGroups-1 Do
		TagName = "GroupSettingsTable" + Cnt;
		Item = Items.Find(TagName);
		If Item <> Undefined Then
			Item.Visible = Cnt < NumberOfOrganizations;
		EndIf;
	EndDo;
	
	// Let's add a conditional design of new columns.
	For Cnt = NumberOfColumnGroupsPreviously To NumberOfColumnGroups - 1 Do
		
		// Conditional registration for the transfer method is "Not required".
		NewElementOfConditionalAppearance = ConditionalAppearance.Items.Add();
		NewElementOfConditionalAppearance.Use = True;
	
		FilterElement = NewElementOfConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.Use = True;
		FilterElement.LeftValue = New DataCompositionField("SettingsTable1.TransferMethod" + Cnt);
		FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
		FilterElement.RightValue = Enums.GoodsTransferMethods.NotRequired;
		
		NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
		NewField.Use = True;
		NewField.Field = New DataCompositionField("SettingsTable1" + "TransferMethod" + Cnt);
		
		NewElementOfConditionalAppearance.Appearance.SetParameterValue("TextColor", StyleColors.BorderColor);
		
		// Conditional registration for an unfilled transfer method.
		NewElementOfConditionalAppearance = ConditionalAppearance.Items.Add();
		NewElementOfConditionalAppearance.Use = True;
	
		FilterElement = NewElementOfConditionalAppearance.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.Use = True;
		FilterElement.LeftValue = New DataCompositionField("SettingsTable1.TransferMethod" + Cnt);
		FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		NewField = NewElementOfConditionalAppearance.Fields.Items.Add();
		NewField.Use = True;
		NewField.Field = New DataCompositionField("SettingsTable1" + "TransferMethod" + Cnt);
		
		NewElementOfConditionalAppearance.Appearance.SetParameterValue("Text", NStr("vi = 'Chưa chuyển giao';
																					|ru = 'Не передается';
																					|en = 'Not transferred'; fa = 'منتقل‌نشده';
																					|it = 'Non trasmesso';
																					|pl = 'Nie przekazuje się';
																					|tr = 'Transfer edilmiyor'"));
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
