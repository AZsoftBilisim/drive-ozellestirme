#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If GetFunctionalOption("UseMultipleCompanies") Then
		Organization = Parameters.Organization;
	EndIf;
	
	ThereMayBeAppointmentsWithoutAnOrder = Documents.InventoryAssignmentAdjustment.AppointmentsWithoutOrderAreAllowed();
	
	UseCostAccountingByLinesOfBusiness = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	
	OrganizationOrdersOnly = ValueIsFilled(Organization)
		And GetFunctionalOption("UseMultipleCompanies");
	Items.OrganizationOrdersOnly.Visible = OrganizationOrdersOnly;
	Items.OrganizationOrdersOnly.Title = StrReplace(NStr("vi = 'Chỉ các đơn đặt hàng từ doanh nghiệp ""%1""';
														|ru = 'Только заказы организации ""%1""';
														|en = 'Only orders of company ""%1""'; fa = 'Only orders of company ""%1""';
														|it = 'Solo ordini della società ""%1""';
														|pl = 'Tylko zamówienia firmy ""%1""';
														|tr = 'Yalnız iş yeri siparişleri ""%1""'"), "%1", Organization);
	
	Items.LineOfBusiness.Visible = UseCostAccountingByLinesOfBusiness;
	If ThereMayBeAppointmentsWithoutAnOrder Then
		Title = NStr("vi = 'Chọn mục đích';
					|ru = 'Выбор назначения';
					|en = 'Select assignment'; fa = 'انتخاب تخصیص';
					|it = 'Selezione di assegnazione';
					|pl = 'Wybór przeznaczenia';
					|tr = 'Atama seçimi'");
	Else
		Title = NStr("vi = 'Lựa chọn đơn hàng';
					|ru = 'Выбор заказа';
					|en = 'Select order'; fa = 'Select order';
					|it = 'Selezione dell''ordine';
					|pl = 'Wybór zamówienia';
					|tr = 'Sipariş seçimi'");
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", Organization,,, OrganizationOrdersOnly);
	
	QueryText =
		"SELECT
		|	AllAssignments.Ref AS Ref,
		|	AllAssignments.OrderDocument AS OrderDocument,
		|	CASE
		|		WHEN DocumentsRegistry.Ref IS NULL
		|			THEN
		|				VALUE(Catalog.Companies.EmptyRef)
		|		ELSE DocumentsRegistry.Organization
		|	END AS Organization,
		|	CASE
		|		WHEN DocumentsRegistry.Ref IS NULL
		|			THEN
		|				CAST("""" AS STRING(50))
		|		ELSE CAST(DocumentsRegistry.Comment AS STRING(50))
		|	END AS Comment,
		|	AllAssignments.LineOfBusiness AS LineOfBusiness,
		|	AllAssignments.Partner AS Partner,
		|	AllAssignments.Contract AS Contract,
		|	CASE
		|		WHEN AllAssignments.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|			THEN
		|				TRUE
		|		ELSE FALSE
		|	END AS NoDirectionOfActivity,
		|	CASE
		|		WHEN AllAssignments.OrderDocument = UNDEFINED
		|			THEN
		|				TRUE
		|		ELSE FALSE
		|	END AS NoOrderRequired,
		|	CASE
		|		WHEN AllAssignments.Partner = VALUE(Catalog.Partners.EmptyRef)
		|			THEN
		|				TRUE
		|		ELSE FALSE
		|	END AS WithoutAPartner,
		|	CASE
		|		WHEN AllAssignments.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
		|			THEN
		|				TRUE
		|		ELSE FALSE
		|	END AS WithoutContract
		|FROM
		|	Catalog.Assignments AS AllAssignments
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|		ON AllAssignments.OrderDocument = DocumentsRegistry.Ref
		|			AND (DocumentsRegistry.AdditionalRecord = FALSE)
		|WHERE
		|	NOT AllAssignments.DeletionMark
		|	AND ISNULL(AllAssignments.LineOfBusiness.Status = VALUE(Enum.LineOfBusinessStatuses.Used), TRUE)
		|	AND &DisplayProcessors";
		
	DisplayProcessors = "TRUE";
		DisplayProcessors =
		"NOT(AllAssignments.AssignmentType = VALUE(Enum.AssignmentTypes.Own)
		|	AND NOT AllAssignments.Partner = VALUE(Catalog.Partners.EmptyRef)
		|	AND NOT AllAssignments.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef))";
	QueryText = StrReplace(QueryText, "&DisplayProcessors", DisplayProcessors);
	
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, List);
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.List, ListProperties);
	SetVisibilityOfDynamicListColumnsByFunctionalOptions();
	SetConditionalAppearance();
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure OrganizationOrdersOnlyOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", Organization,,, OrganizationOrdersOnly);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	// The color of the inaccessible text of unfilled cells.
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Partner");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WithoutAPartner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ định bạn hàng>';
													|ru = '<без указания партнера>';
													|en = '<without partner specified>'; fa = '<without partner specified>';
													|it = '<senza indicare il partner>';
													|pl = '<bez wskazania partnera>';
													|tr = '<iş ortağı belirtmeden>'"));
	
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Contract");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WithoutContract");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ định hợp đồng>';
													|ru = '<без указания договора>';
													|en = '<without contract specified>'; fa = '<without contract specified>';
													|it = '<senza indicare l''accordo>';
													|pl = '<bez wskazania kontraktu>';
													|tr = '<sözleşme belirtmeden>'"));
	
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("OrderDocument");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NoOrderRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ định đơn hàng>';
													|ru = '<без указания заказа>';
													|en = '<without order specified>'; fa = '<without order specified>';
													|it = '<senza indicare l''ordine>';
													|pl = '<bez wskazania zamówienia>';
													|tr = '<sipariş belirtmeden>'"));
	
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Organization");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NoOrderRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("LineOfBusiness");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NoDirectionOfActivity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ định lĩnh vực hoạt động>';
													|ru = '<без указания направления деятельности>';
													|en = '<without line of business specified>'; fa = '<without line of business specified>';
													|it = '<senza indicare il settore di attività>';
													|pl = '<bez podania rodzaju działalności>';
													|tr = '<iş kolu belirtmeden>'"));
	
EndProcedure

&AtServer
Procedure SetVisibilityOfDynamicListColumnsByFunctionalOptions()
	
	If Not GetFunctionalOption("EnterpriseManagement")
		Or (True
			And Not GetFunctionalOption("UseProductionByThirdParty2_5")
			And Not GetFunctionalOption("UseTollManufacturing2_5")
			And True) Then
		
		Items.Partner.Visible = False;
		Items.Contract.Visible = False;
		
	EndIf;
	
EndProcedure

#EndRegion
