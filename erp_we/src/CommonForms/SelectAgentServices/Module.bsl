
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Principal = Parameters.Principal;
	CalledFormID = Parameters.UUID;
	If Parameters.Property("IsPick") Then
		IsPick = Parameters.IsPick;
	Else 
		IsPick = False;
	EndIf;
	
	SetConditionalAppearance();
	SetVisibilityBySelection();
	FillInTableOfServices();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TransferToTheCatalogExecute()
	
	Close(DialogReturnCode.OK);
	
	If IsPick Then
		AddressOfServiceInVault = PutServicesInStorage();
		NotifyChoice(AddressOfServiceInVault);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectRowsExecute()

	For Each TableRow In ServicesTable Do
		TableRow.Selected = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearRowsExecute()

	For Each TableRow In ServicesTable Do
		TableRow.Selected = False
	EndDo;
	
EndProcedure

&AtClient
Procedure SelectSelectedRows(Command)
	
	RowsArray = Items.ServicesTable.SelectedRows;
	For Each LineNumber In RowsArray Do
		TableRow = ServicesTable.FindByID(LineNumber);
		If TableRow <> Undefined Then
			TableRow.Selected = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearSelectedRows(Command)
	
	RowsArray = Items.ServicesTable.SelectedRows;
	For Each LineNumber In RowsArray Do
		TableRow = ServicesTable.FindByID(LineNumber);
		If TableRow <> Undefined Then
			TableRow.Selected = False;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	If Not IsPick Then
		Return;
	EndIf;
	
	ConditionalAppearance.Items.Clear();
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ServicesTable.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ServicesTable.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.RosyBrown);
	
EndProcedure

&AtServer
Procedure SetVisibilityBySelection()
	
	If Not IsPick Then
		TMCommonUseClientServer.SetFormItemProperty(Items,"ServicesTableSelected","Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items,"SelectMarked","Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items,"ClearMarked","Visible", False);
		TMCommonUseClientServer.SetFormItemProperty(Items,"TransferToTheCatalog","Title", "Close");
		Title = NStr("vi = 'Dịch vụ đại lý';
					|ru = 'Агентские услуги';
					|en = 'Agent services'; fa = 'خدمات عاملیت';
					|it = 'Servizi di agenzia';
					|pl = 'Usługi agenckie';
					|tr = 'Acente hizmeti'");
	EndIf;
	
EndProcedure

#Region Other

&AtServer
Function PutServicesInStorage() 
	
	Services = ServicesTable.Unload(, "Selected, Products, Characteristic");
	
	ArrayOfRowsToDelete_1 = New Array;
	For Each TableRow In Services Do
		If Not TableRow.Selected Then
			ArrayOfRowsToDelete_1.Add(TableRow);
		EndIf;
	EndDo;
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		Services.Delete(TableRow);
	EndDo;

	Return PutToTempStorage(Services, CalledFormID);
	
EndFunction

&AtServer
Procedure DownloadRecruitmentServices()
		
	Query = New Query;
	Query.Text =
	"SELECT
	|	Services.Products AS Products,
	|	Services.Characteristic AS Characteristic,
	|	TRUE AS Selected
	|INTO SelectedServices
	|FROM
	|	&Services AS Services
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Services.Products AS Products,
	|	Services.Characteristic AS Characteristic,
	|	TRUE AS Selected
	|FROM
	|	SelectedServices AS Services
	|
	|UNION ALL
	|
	|SELECT
	|	CatProducts.Ref,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
	|	FALSE
	|FROM
	|	Catalog.Products AS CatProducts
	|		LEFT JOIN SelectedServices AS Services
	|		ON (Services.Products = CatProducts.Ref)
	|			AND (Services.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|WHERE
	|	NOT CatProducts.IsFolder
	|	AND CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|	AND CatProducts.Principal = &Principal
	|	AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|	AND Services.Products IS NULL 
	|
	|UNION ALL
	|
	|SELECT
	|	CatProducts.Ref,
	|	ItemsCharacteristics.Ref,
	|	FALSE
	|FROM
	|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON (CASE
	|				WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|					THEN CatProducts.Ref
	|				WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|					THEN CatProducts.ProductKind
	|				WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|					THEN CatProducts.ItemVariantsOwner
	|				ELSE UNDEFINED
	|			END = ItemsCharacteristics.Owner)
	|		LEFT JOIN SelectedServices AS Services
	|		ON (Services.Products = CatProducts.Ref)
	|			AND (Services.Characteristic = ItemsCharacteristics.Ref)
	|WHERE
	|	CatProducts.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems), VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|	AND ItemsCharacteristics.Principal = &Principal
	|	AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|	AND Services.Products IS NULL ";
		
	Services = GetFromTempStorage(CalledFormID); // ValueTable
	Services.GroupBy("Products, Characteristic");
	Query.SetParameter("Services", Services);
	Query.SetParameter("Principal", Principal);
	
	ServicesTable.Load(Query.Execute().Unload());
	
EndProcedure

&AtServer
Procedure FillInAllAgencyServicesByPrincipal()
		
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CatProducts.Ref AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	FALSE AS Selected
	|FROM
	|	Catalog.Products AS CatProducts
	|WHERE
	|	NOT CatProducts.IsFolder
	|	AND CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|	AND CatProducts.Principal = &Principal
	|	AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|
	|UNION ALL
	|
	|SELECT
	|	CatProducts.Ref,
	|	ItemsCharacteristics.Ref,
	|	FALSE
	|FROM
	|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON (CASE
	|				WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|					THEN CatProducts.Ref
	|				WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|					THEN CatProducts.ProductKind
	|				WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|					THEN CatProducts.ItemVariantsOwner
	|				ELSE UNDEFINED
	|			END = ItemsCharacteristics.Owner)
	|WHERE
	|	CatProducts.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems), VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|	AND ItemsCharacteristics.Principal = &Principal
	|	AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.OperationService)";
	Query.SetParameter("Principal", Principal);
	ServicesTable.Load(Query.Execute().Unload());
	
EndProcedure

&AtServer
Procedure FillInTableOfServices()
	
	If IsPick Then
		DownloadRecruitmentServices();
	Else
		FillInAllAgencyServicesByPrincipal();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
