
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("DimensionType", DimensionType) Then
		MessageText = NStr("vi = 'Không xem xét mở trực tiếp biểu mẫu này. Thực hiện mở biểu mẫu khi thêm chiều đo vào dạng ngân sách.';
							|ru = 'Непосредственное открытие этой формы не предусмотрено. Открытие формы выполняется при добавлении измерения в вид бюджета.';
							|en = 'Application cannot open this form explicitly. It opens implicitly when you add a dimension to a budget profile.'; fa = 'Application cannot open this form explicitly. It opens implicitly when you add a dimension to a budget profile.';
							|it = 'L''apertura diretta di questo modulo non è prevista. L''apertura del modulo viene eseguita quando si aggiunge una dimensione nel tipo di budget.';
							|pl = 'Bezpośrednie otwieranie tego formularza nie jest przewidziane. Otwarcie formularza jest wykonywane przy dodaniu wymiaru do rodzaju budżetu.';
							|tr = 'Bu formların direkt açılmaları öngörülmedi. Formların açılmaları bütçe profiline boyut eklendiğinde gerçekleştirilir.'");
		Raise MessageText;
	EndIf;
	
	If DimensionType = Enums.TypesOfBudgetReportDimensions.Dimension Then
		SelectedValues.ValueType = Parameters.AdditionalInformation.ValueType;
		Title = String(Parameters.AdditionalInformation) + ":";
		DimensionKind = Parameters.AdditionalInformation;
	ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension
		And Parameters.AdditionalInformation = "Organization" Then
		SelectedValues.ValueType = New TypeDescription("CatalogRef.Companies");
		Title = NStr("vi = 'Doanh nghiệp:';
					|ru = 'Организация:';
					|en = 'Company:'; fa = 'شرکت:';
					|it = 'Azienda:';
					|pl = 'Firma:';
					|tr = 'İş yeri:'");
		RegisterDimensionName = Parameters.AdditionalInformation;
	ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension
		And Parameters.AdditionalInformation = "Department" Then
		SelectedValues.ValueType = New TypeDescription("CatalogRef.BusinessStructure");
		Title = NStr("vi = 'Bộ phận:';
					|ru = 'Подразделение:';
					|en = 'Business unit:'; fa = 'واحد تجاری:';
					|it = 'Reparto:';
					|pl = 'Dział:';
					|tr = 'Departman:'");
		RegisterDimensionName = Parameters.AdditionalInformation;
	ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension
		And Parameters.AdditionalInformation = "Scenario" Then
		SelectedValues.ValueType = New TypeDescription("CatalogRef.BudgetingScenarios");
		Title = NStr("vi = 'Kịch bản lập kế hoạch:';
					|ru = 'Сценарий планирования:';
					|en = 'Planning scenario:'; fa = 'Planning scenario:';
					|it = 'Scenario di pianificazione:';
					|pl = 'Scenariusz planowania:';
					|tr = 'Planlama senaryosu:'");
		RegisterDimensionName = Parameters.AdditionalInformation;
	ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension
		And Parameters.AdditionalInformation = "Currency" Then
		SelectedValues.ValueType = New TypeDescription("CatalogRef.Currencies");
		Title = NStr("vi = 'Tiền tệ:';
					|ru = 'Валюта:';
					|en = 'Currency:'; fa = 'ارز:';
					|it = 'Valuta:';
					|pl = 'Waluta:';
					|tr = 'Para birimi:'");
		RegisterDimensionName = Parameters.AdditionalInformation;
	ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension
		And Parameters.AdditionalInformation = "UnitOfMeasure" Then
		SelectedValues.ValueType = New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure");
		Title = NStr("vi = 'Bộ đóng gói:';
					|ru = 'Упаковка:';
					|en = 'Packaging unit:'; fa = 'واحد بسته‌بندی:';
					|it = 'Imballaggio:';
					|pl = 'Opakowanie:';
					|tr = 'Paket:'");
		RegisterDimensionName = Parameters.AdditionalInformation;
	Else
		Raise NStr("vi = 'Kiểu chiều đo không xác định của báo cáo ngân sách';
					|ru = 'Неизвестный тип измерения бюджетного отчета';
					|en = 'Unknown budget report dimension type'; fa = 'Unknown budget report dimension type';
					|it = 'Tipo sconosciuto della misura del rapporto di bilancio';
					|pl = 'Nieznany typ wymiaru raportu budżetowego';
					|tr = 'Bütçe raporu ölçüm türü bilinmiyor'");
	EndIf;
	
	If Parameters.UseToEnterPlan Then
		FixedValue = 1;
		UseToEnterPlan = True;
		Items.AllValues.ExtendedTooltip.Title = NStr("vi = 'Trong ngân sách, có thể tự động điền đối tượng phân tích bởi tất cả giá trị của nó.';
													|ru = 'В бюджете можно будет заполнить аналитику автоматически всеми ее значениями.';
													|en = 'Dimension can be automatically populated with all its values in the budget.'; fa = 'Dimension can be automatically populated with all its values in the budget.';
													|it = 'Nel budget sarà possibile compilare automaticamente le analisi con tutti i suoi valori.';
													|pl = 'W budżecie można będzie automatycznie wypełnić analitykę wszystkimi jej znaczeniami.';
													|tr = 'Bütçede boyut alanlarını tüm değerleriyle otomatik olarak doldurmak mümkün olacaktır.'");
	Else
		Items.AllValues.ExtendedTooltip.Title = NStr("vi = 'Sẽ liệt kê tất cả giá trị có số phát sinh hoặc số dư.';
													|ru = 'Будут перечислены все значения, по которым есть обороты или остатки';
													|en = 'All values that have a related turnover or balance will be listed'; fa = 'همه مقادیری که گردش یا مانده مرتبط دارند فهرست خواهند شد';
													|it = 'Verranno elencati tutti i valori su cui sono presenti giri o saldi';
													|pl = 'Zostaną wymienione wszystkie wartości, dla których istnieją obroty lub ostatki';
													|tr = 'Tüm değerler cirolara veya mal stoklarına göre listelenecek'");
	EndIf;
	
	If DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension Then
		Items.GroupSelectFixedValues.CurrentPage = Items.Dimensions;
	Else
		Items.GroupSelectFixedValues.CurrentPage = Items.FixedDimensions;
		If Not Parameters.UseToEnterPlan Or Parameters.ToColumns Then
			Items.EditVisibilityGroup.CurrentPage = Items.EditingIsNotAvailable;
		EndIf;
	EndIf;
	
	Owner = Parameters.Owner;
	If Owner <> Undefined Then
		SelectedValues.ValueType = New TypeDescription(Owner.Types);
		ValuesOwner = Owner.Value;
		AddLinksOfSelectionParametersByOwner(Owner);
	EndIf;
	
	HierarchyOfValuesIsUsed = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.HierarchyOfAnalyticsValuesIsUsed(DimensionKind);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FixedValueWhenChanging(Undefined);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FixedValueWhenChanging(Item)
	
	If FixedValue Then
		DisplayHierarchyOfValues = False;
	EndIf;
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure AddOtherValuesOnChange(Item)
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure ToAllowTheAdditionOfIfYouChange(Item)
	
	If EnableEdit Then
		AddOtherValues = True;
	EndIf;
	
	FormControl(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	Close(GetChoiceResult());
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AddResultLine(Result, ItemIndicatorDimensionType, DimensionValue = Undefined, ThisIsDimensionOther = False, AllValues = False)
	
	NewRow = New Structure;
	
	NameForPrinting = TrimAll(?(ValueIsFilled(DimensionValue), DimensionValue, ItemIndicatorDimensionType))
						+ ?(DisplayHierarchyOfValues, " Hierarchy", "");
	NewRow.Insert("NameForPrinting", NameForPrinting);
	NewRow.Insert("ItemIndicatorDimensionType", ItemIndicatorDimensionType);
	NewRow.Insert("DimensionValue", DimensionValue);
	NewRow.Insert("ThisIsDimensionOther", ThisIsDimensionOther);
	NewRow.Insert("EnableEdit", EnableEdit);
	NewRow.Insert("AllValues", AllValues);
	NewRow.Insert("ShowItemHierarchy", DisplayHierarchyOfValues);
	
	Result.Add(NewRow);
	
EndProcedure

&AtServer
Function GetChoiceResult()
	
	Result = New Array;
	
	If DimensionType = Enums.TypesOfBudgetReportDimensions.RegisterDimension Then
		If Not FixedValue Then
			AddResultLine(Result, RegisterDimensionName, StrReplace(Title, ":", ""));
		Else
			For Each Item In SelectedValues Do
				If Not ValueIsFilled(Item.Value) Then
					Continue;
				EndIf;
				AddResultLine(Result, Item.Value);
			EndDo;
		EndIf;
	ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.Dimension Then
		
		If Not FixedValue And Not UseToEnterPlan Then
			AddResultLine(Result, DimensionKind);
		Else
			For Each Item In SelectedValues Do
				If Not ValueIsFilled(Item.Value) Then
					Continue;
				EndIf;
				AddResultLine(Result, DimensionKind, Item.Value);
			EndDo;
			If AddOtherValues Then
				If Not FixedValue Then
					AddResultLine(Result, DimensionKind, , True, True);
				Else
					AddResultLine(Result, DimensionKind, , True);
				EndIf;
			EndIf;
		EndIf;
	Else
		Raise NStr("vi = 'Kiểu chiều đo trong báo cáo ngân sách không xác định';
					|ru = 'Неизвестный тип измерения бюджетного отчета';
					|en = 'Unknown budget report dimension type'; fa = 'Unknown budget report dimension type';
					|it = 'Tipo sconosciuto della misura del rapporto di bilancio';
					|pl = 'Nieznany typ wymiaru raportu budżetowego';
					|tr = 'Bütçe raporu ölçüm türü bilinmiyor'");
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function TypeSelectionListItems(ValueType)
	
	Types = New ValueList;
	For Each Type In ValueType.Types() Do
		Types.Add(Type, Metadata.FindByType(Type).Synonym);
	EndDo;
	
	Return Types;
	
EndFunction

&AtServerNoContext
Function GetFormName(TypeOfSelection_)
	
	FullName = Metadata.FindByType(TypeOfSelection_).FullName();
	Return FullName + ".ChoiceForm";
	
EndFunction

&AtServerNoContext
Function GetFormParameters(ValuesOwner, TypeOfSelection_)
	
	RedefinedOwner = FinancialReportingCached.MatchingSelectionsByOwner()[TypeOfSelection_];
	FormParameters = New Structure(
			"MultipleChoice, ChoiceMode, CloseOnChoice", 
			True, True, False);
	
	If ValueIsFilled(ValuesOwner) Then
		If RedefinedOwner <> Undefined Then
			OwnerParameters = RedefinedOwner.Find(TypeOf(ValuesOwner), "Type");
			Filter = New Structure(OwnerParameters.Attribute, ValuesOwner);
		Else
			Filter = New Structure("Owner", ValuesOwner);
		EndIf;
		FormParameters.Insert("Filter", Filter);
	EndIf;
	
	Return FormParameters;
	
EndFunction

&AtClient
Procedure Pickup(Command)
	
	Types = TypeSelectionListItems(SelectedValues.ValueType);
	If Types.Count() = 0 Then
		Return;
	ElsIf Types.Count() = 1 Then
		TypeOfSelection_ = Types[0].Value;
	Else
		SelectionResult = Types.ChooseItem(NStr("vi = 'Hãy chọn kiểu giá trị';
												|ru = 'Выберите тип значения';
												|en = 'Select value type'; fa = 'انتخاب نوع مقدار';
												|it = 'Selezionate il tipo di valore';
												|pl = 'Wybierz typ wartości';
												|tr = 'Değer türü seç'"));
		If SelectionResult = Undefined Then
			Return;
		EndIf;
		TypeOfSelection_ = SelectionResult.Value;
	EndIf;
	
	FormParameters = GetFormParameters(ValuesOwner, TypeOfSelection_);
	
	OpenForm(GetFormName(TypeOfSelection_), FormParameters, Items.SelectedMeasurementValues, , , , , FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	Form.Items.TheSelectedValuesAnalyst.Enabled = Form.FixedValue;
	Form.Items.SelectedMeasurementValues.Enabled = Form.FixedValue;
	Form.Items.EditVisibilityGroup.Enabled = Form.FixedValue;
	AddOtherValues = Form.FixedValue And Not Form.EnableEdit;
	Form.Items.EnableEdit.Enabled = Form.FixedValue;
	Form.Items.AddOtherValues.Enabled = AddOtherValues;
	Form.Items.DisplayHierarchyOfValues.Enabled = Not Form.FixedValue
		And Form.HierarchyOfValuesIsUsed;
	
	If Form.UseToEnterPlan Then
		If Not Form.FixedValue Then
			Form.EnableEdit = True;
			Form.AddOtherValues = True;
			Form.Items.EnableEdit.ExtendedTooltip.Title = NStr("vi = 'Có thể thêm các giá trị phân tích vào bản ghi ngân sách một cách thủ công hoặc tự động điền bởi tất cả giá trị. Sẽ thêm phần tử <tất cả giá trị> vào dạng ngân sách';
																|ru = 'В экземпляр бюджета можно будет добавлять значения аналитики вручную или заполнить автоматически всеми значениями. В вид бюджета будет добавлен элемент <все значения>';
																|en = 'Dimension values can be added manually to the Budget entry form or auto populated with all values. The <all values> item will be added to the budget profile'; fa = 'Dimension values can be added manually to the Budget entry form or auto populated with all values. The <all values> item will be added to the budget profile';
																|it = 'In una copia del budget sarà possibile aggiungere manualmente i valori dell''analisi o compilare i dati automaticamente con tutti i valori. Nel tipo di budget verrà aggiunto elemento <tutti i valori>';
																|pl = 'Do egzemplarza budżetu można będzie ręcznie dodać wartości analityki lub wypełnić je automatycznie wszystkimi wartościami. Do rodzaju budżetu zostanie dodany element <wszystkie wartości>';
																|tr = 'Bütçe giriş formunda boyut değerlerini manuel olarak veya  tüm değerleri otomatik olarak eklemek mümkün olacaktır. Bütçe profilinde <tüm değerler> öğesi eklenecektir'");
		Else
			Form.Items.EnableEdit.ExtendedTooltip.Title = NStr("vi = 'Có thể thêm vào bản ghi ngân sách các giá trị phân tích một cách thủ công hoặc điền theo giá trị hoạch định ngân sách. Có thể thêm phần tử <giá trị thêm mới và giá trị khác> vào dạng ngân sách';
																|ru = 'В экземпляр бюджета можно будет добавлять значения аналитики вручную или заполнить по данным бюджетирования. В вид бюджета будет добавлен элемент <добавляемые и прочие значения>';
																|en = 'Dimension values can be added manually to the Budget entry form or populated according to the budgeting data. The <added and other values> item will be added to the budget profile'; fa = 'مقادیر بُعد می‌توانند به صورت دستی به فرم ورود بودجه اضافه شوند یا بر اساس داده‌های بودجه‌بندی پر شوند. قلم <مقادیر اضافه‌شده و سایر مقادیر> به پروفایل بودجه اضافه خواهد شد';
																|it = 'È possibile aggiungere manualmente i valori di dimensione all''istanza del budget o compilare i dati di budget. Nella vista budget viene aggiunto l''elemento <valori aggiunti e altri >';
																|pl = 'Do egzemplarza budżetu można będzie ręcznie dodać wartości analityki lub wypełnić je automatycznie danymi budżetowania. Do rodzaju budżetu zostanie dodany element <dodawane i inne wartości>';
																|tr = 'Bütçe giriş formunda, iç boyut değerleri eklenebilecektir veya bütçeleme verilerine göre doldurulabilecektir. Bütçe profilinde <eklenebilir olanlar ve diğer değerler> öğesi eklenecektir'");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectAdditionalFields(Command)

	OpenForm("Catalog.FinancialReportItems.Form.SetUpAdditionalFields",,,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure AddLinksOfSelectionParametersByOwner(Owner)
	
	If TypeOf(Owner) = Type("Structure") And Owner.Property("Attribute") 
			And ValueIsFilled(Owner.Attribute) Then
		ParameterRelationships = New ChoiceParameterLink(
			"Filter."+Owner.Attribute,"ValuesOwner");
		Array = CommonClientServer.ValueInArray(ParameterRelationships);
		Items.SelectedValuesValue.ChoiceParameterLinks = New FixedArray(Array);
	ElsIf TypeOf(ValuesOwner) = Type("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo")
		And Common.ObjectAttributeValue(ValuesOwner, "ValueType") = New TypeDescription("CatalogRef.ObjectsPropertiesValues") Then
		ParameterRelationships = New ChoiceParameterLink(
			"Filter.Owner","ValuesOwner");
		Array = CommonClientServer.ValueInArray(ParameterRelationships);
		Items.SelectedValuesValue.ChoiceParameterLinks = New FixedArray(Array);
	EndIf;

EndProcedure

#EndRegion

