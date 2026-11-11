#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	Organization = Undefined;
	Department = Undefined;
	If Parameters.Property("Filter") Then
		Parameters.Filter.Property("Organization", Organization);
		Parameters.Filter.Property("Department", Department);
		Items.FilterText1.Visible = True;
		FilterText1 = NStr("vi = 'Doanh nghiệp: %1, Bộ phận: %2';
							|ru = 'Организация: %1, Подразделение: %2';
							|en = 'Company: %1, Business unit: %2'; fa = 'Company: %1, Business unit: %2';
							|it = 'Società: %1, Reparto: %2';
							|pl = 'Firma: %1, Dział: %2';
							|tr = 'İş yeri: %1, Departman:%2'");
		FilterText1 = StrReplace(FilterText1, "%1", String(Organization));
		FilterText1 = StrReplace(FilterText1, "%2", String(Department));
		
		If Parameters.Filter.Property("LineOfBusiness", LineOfBusiness)
			And Not GetFunctionalOption("TradeManagement") Then
			
				If ValueIsFilled(LineOfBusiness) Then
					FilterText1 = FilterText1 + ", " + NStr("vi = 'Lĩnh vực hoạt động: %1';
															|ru = 'Направление деятельности: %1';
															|en = 'Line of business: %1'; fa = 'Line of business: %1';
															|it = 'Settore di attività: %1';
															|pl = 'Rodzaj działalności: %1';
															|tr = 'İş kolu: %1'");
					FilterText1 = StrReplace(FilterText1, "%1", String(LineOfBusiness));
				Else
					FilterText1 = FilterText1 + ", " + NStr("vi = 'Không chỉ ra lĩnh vực hoạt động';
															|ru = 'Без указания направления деятельности';
															|en = 'Without specifying line of business'; fa = 'Without specifying line of business';
															|it = 'Senza specificare il settore di attività';
															|pl = 'Bez podania kierunku działalności';
															|tr = 'Faaliyet yönünü belirtmeden'");
				EndIf;
			
		EndIf;
		
		Items.FilterText1.Title = FilterText1;
		
	EndIf;
	Items.ListCharacteristic.Visible = GetFunctionalOption("UseItemVariants");
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	RestoreSettings();
	FillList();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	SaveSettingsAndFillInList();
	
EndProcedure

&AtClient
Procedure EndOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	SaveSettingsAndFillInList();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveGoodsFromDocuments(Command)
	
	PutProductsInStorage();
	NotifyChoice(New Structure("GoodsAddressInStorage", GoodsAddressInStorage));
	
EndProcedure

&AtClient
Procedure SelectDocuments(Command)
	
	For Each String In List Do
		String.Selected = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearDocuments(Command)
	
	For Each String In List Do
		String.Selected = False;
	EndDo;
	
EndProcedure

&AtClient
Procedure SelectPeriod(Command)
	
	PeriodParameters_   = New Structure("StartDate, EndDate", "BeginOfPeriod", "EndOfPeriod");
	CallbackDescription = New CallbackDescription("SelectPeriodCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(
		ThisForm, PeriodParameters_, CallbackDescription);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm,
																			"ListCharacteristic",
																			"List.ItemVariantsAreUsed");
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ListUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "List.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

EndProcedure

&AtClient
// The procedure gets the result of the period selection and fills in the list.
//
// Parameters:
//  The result of the selection - Structure - the result of the selection of the period
//  Dopparameters - Structure - additional parameters passed to the procedure.
//
Procedure SelectPeriodCompletion(SelectionResult, AddlParameters) Export
	
	If SelectionResult = Undefined Then
		Return;
	EndIf;
	
	FillList();
	
EndProcedure

&AtServer
Procedure PutProductsInStorage() 
	
	Goods = List.Unload(New Structure("Selected", True), "Selected, Products, Characteristic, Purpose, ExpenseItem, DimensionOfExpenses, ExpenseAs, Package, UnitOfMeasure, NumberOfPackages");
	
	GoodsAddressInStorage = PutToTempStorage(Goods, UUID);
	
EndProcedure

&AtServer
Procedure FillList()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	T.Products,
	|	T.Characteristic,
	|	CASE
	|		WHEN VALUETYPE(Assignments.OrderDocument) = TYPE(Document.InventoryConsumptionOrder)
	|			OR VALUETYPE(Assignments.OrderDocument) = TYPE(Document.RMOrder)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE T.Purpose
	|	END AS Purpose,
	|	CASE
	|		WHEN CatProducts.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems), VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			THEN TRUE
	|		ELSE CASE
	|				WHEN T.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|					THEN FALSE
	|				ELSE TRUE
	|			END
	|	END AS ItemVariantsAreUsed,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	Doc.EmployeeResponsible,
	|	T.Ref AS ExpenseAs,
	|	Doc.Date,
	|	Doc.Warehouse,
	|	T.Package,
	|	T.Products.UnitOfMeasure AS UnitOfMeasure,
	|	SUM(T.NumberOfPackages) AS NumberOfPackages
	|FROM
	|	Document.InventoryConsumption.Goods AS T
	|		INNER JOIN Document.InventoryConsumption AS Doc
	|		ON T.Ref = Doc.Ref
	|			AND (Doc.Organization = UNDEFINED
	|				OR Doc.Organization = &Organization)
	|			AND (&Department = UNDEFINED
	|				OR Doc.Department = &Department)
	|			AND Doc.LineOfBusiness = &LineOfBusiness
	|			AND (Doc.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand))
	|			AND (Doc.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod)
	|			AND (Doc.Posted)
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON T.Products = CatProducts.Ref
	|		LEFT JOIN Catalog.Assignments AS Assignments
	|		ON T.Purpose = Assignments.Ref
	|WHERE
	|	NOT T.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|GROUP BY
	|	T.Products,
	|	T.Characteristic,
	|	CASE
	|		WHEN VALUETYPE(Assignments.OrderDocument) = TYPE(Document.InventoryConsumptionOrder)
	|			OR VALUETYPE(Assignments.OrderDocument) = TYPE(Document.RMOrder)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE T.Purpose
	|	END,
	|	CASE
	|		WHEN CatProducts.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems), VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			THEN TRUE
	|		ELSE CASE
	|				WHEN T.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|					THEN FALSE
	|				ELSE TRUE
	|			END
	|	END,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses,
	|	Doc.EmployeeResponsible,
	|	T.Ref,
	|	Doc.Date,
	|	Doc.Warehouse,
	|	T.Package,
	|	T.Products.UnitOfMeasure";
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Department", Department);
	Query.SetParameter("LineOfBusiness", LineOfBusiness);
	If Not ValueIsFilled(BeginOfPeriod) Then
		BeginOfPeriod = BegOfMonth(BegOfMonth(CurrentSessionDate()) - 1);
		Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Else
		Query.SetParameter("BeginOfPeriod", BegOfDay(BeginOfPeriod));
	EndIf;
	If Not ValueIsFilled(EndOfPeriod) Then
		EndOfPeriod = EndOfMonth(CurrentSessionDate());
		Query.SetParameter("EndOfPeriod", EndOfDay(EndOfPeriod));
	Else
		Query.SetParameter("EndOfPeriod", EndOfDay(EndOfPeriod));
	EndIf;
	List.Load(Query.Execute().Unload());
	
EndProcedure

&AtServer
Procedure RestoreSettings()
	
	SettingsValue = Common.CommonSettingsStorageLoad("Document.InventoryConsumption", "SelectionOfWriteOffDocuments");
	
	BeginOfPeriod = '00010101';
	EndOfPeriod  = '00010101';
	If TypeOf(SettingsValue) = Type("Structure") Then
		
		FillPropertyValues(ThisForm, SettingsValue);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveSettingsAndFillInList()
	
	AttributesToSaveNames = "BeginOfPeriod,EndOfPeriod";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, ThisForm);
	
	Common.CommonSettingsStorageSave("Document.InventoryConsumption", "SelectionOfWriteOffDocuments", Settings);
	
	FillList();
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_F_EndOfPeriod" Then
		EndOfPeriodOnChange(Items.EndOfPeriod);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
