
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// Fill in the list of selected operations - add only those for which there are configurable parameters.
	Items.Operation.ChoiceList.Clear();
	
	AllParameters = Constants.MonthEndClosingSettings.CreateValueManager().ReadAllParameters();
	
	For Each KeyAndValue In AllParameters Do
		
		PresentationOperation = ?(ValueIsFilled(KeyAndValue.Key),
			TrimAll(KeyAndValue.Key),
			"<" + NStr("vi = 'Thông số chung của tất cả các hoạt động';
						|ru = 'Общие параметры всех операций';
						|en = 'General parameters of all operations'; fa = 'General parameters of all operations';
						|it = 'Parametri generali di tutte le operazioni';
						|pl = 'Ogólne ustawienia wszystkich operacji';
						|tr = 'Tüm işlemlerin genel parametreleri'", Common.DefaultLanguageCode()) + ">");
		
		Items.Operation.ChoiceList.Add(KeyAndValue.Key, PresentationOperation);
		
	EndDo;
	
	If Items.Operation.ChoiceList.Count() = 0 Then
		
		CommonClientServer.MessageToUser(NStr("vi = 'Không có thông số tùy chỉnh để đóng một tháng';
												|ru = 'Нет настраиваемых параметров операций закрытия месяца';
												|en = 'No configured parameters of month-end closing operations'; fa = 'No configured parameters of month-end closing operations';
												|it = 'Non ci sono parametri impostabili per le operazioni di chiusura del mese';
												|pl = 'Nie ma konfigurowalnych ustawień operacji zamknięcia miesiąca';
												|tr = 'Ay sonu kapanış işlemleri için yapılandırılabilir seçenek yok'", Common.DefaultLanguageCode()));
		Cancel = True;
		Return;
		
	EndIf;
	
	Items.Operation.ChoiceList.SortByValue();
	
	// Fill in the parameters of the first operation.
	ParametersDetails = New ValueStorage(AllParameters, New Deflation(9));
	
	If TypeOf(Parameters.Operation) = TypeOf(Operation) Then
		Operation = Parameters.Operation;
	Else
		Operation = Items.Operation.ChoiceList.Get(0).Value;
	EndIf;
	
	PreviousOperation = Operation;
	
	FillInOperationParameters(False);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Items.Operation.ChoiceList.FindByValue(Operation) = Undefined Then
		Operation = PreviousOperation; // there are no settings for this operation
		Return;
	EndIf;
	
	PreviousOperation = Operation;
	
	FillInOperationParameters(False);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetDefaultValues(Command)
	
	For Each GroupRow In CalculationParameterTree.GetItems() Do
		
		If GroupRow.IsFolder Then
			
			For Each ParameterString In GroupRow.GetItems() Do
				ParameterString.Value = ParameterString.DefaultValue;
				ParameterString.ValueChanged = False;
			EndDo;
			
			GroupRow.ValueChanged = False;
			
		Else
			
			GroupRow.Value = GroupRow.DefaultValue;
			GroupRow.ValueChanged = False;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SaveAndLoad(Command)
	
	Save(Command);
	Close();
	
EndProcedure

&AtClient
Procedure Save(Command)
	
	SaveParameters();
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure OperationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure OperationOnChange(Item)
	
	FillInOperationParameters();
	
EndProcedure


&AtClient
Procedure CalculationParameterTreeOnActivateRow(Item)
	
	// Let's output an explanation of the parameter.
	ExplanationOfTheParameter = "";
	
	RowData = Items.CalculationParameterTree.CurrentData;
	If RowData = Undefined Then
		Return;
	EndIf;
	
	ExplanationOfTheParameter = RowData.LongDesc;
	
	If Not RowData.IsFolder Then
		
		ExplanationOfTheParameter = ExplanationOfTheParameter + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Giá trị mặc định: %1';
				|ru = 'Значение по умолчанию: %1';
				|en = 'Default value: %1'; fa = 'Default value: %1';
				|it = 'Valore per default: %1';
				|pl = 'Wartość domyślna: %1';
				|tr = 'Varsayılan değer: %1'", CommonClientServer.DefaultLanguageCode()),
			TrimAll(RowData.DefaultValue));
			
		If RowData.RangeWith <> Undefined Or RowData.RangeBy <> Undefined Then
			
			ExplanationOfTheParameter = ExplanationOfTheParameter + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Phạm vi giá trị: (%1; %2)';
					|ru = 'Диапазон значений: (%1; %2)';
					|en = 'Value range: (%1; %2)'; fa = 'Value range: (%1; %2)';
					|it = 'Intervallo di valori: (%1; %2)';
					|pl = 'Zakres wartości: (%1; %2)';
					|tr = 'Değer aralığı: (%1; %2)'", CommonClientServer.DefaultLanguageCode()),
				?(RowData.RangeWith = Undefined, "...", Format(RowData.RangeWith, "NZ=0")),
				?(RowData.RangeBy = Undefined, "...", Format(RowData.RangeBy, "NZ=0")));
			
		EndIf;
		
	EndIf;
	
	// Configure the parameter input field.
	If RowData.IsFolder Then
		
		Items.CalculationParameterTreeParameterValue.ReadOnly = True;
		
	Else
		
		// The range of the value.
		Items.CalculationParameterTreeParameterValue.ReadOnly = False;
		
		If RowData.ValueType.ContainsType(Type("Number")) Then
			
			If RowData.RangeWith = Undefined Then
				RangeWith = -999999999;
			Else
				RangeWith = RowData.RangeWith;
			EndIf;
			
			If RowData.RangeBy = Undefined Then
				RangeBy = 999999999;
			Else
				RangeBy = RowData.RangeBy;
			EndIf;
			
		Else
			
			RangeWith = Undefined;
			RangeBy = Undefined;
			
		EndIf;
		
		Items.CalculationParameterTreeParameterValue.MinValue =
			RowData.ValueType.AdjustValue(RangeWith);
		Items.CalculationParameterTreeParameterValue.MaxValue =
			RowData.ValueType.AdjustValue(RangeBy);
		
		// Selection list.
		Items.CalculationParameterTreeParameterValue.ChoiceList.Clear();
		
		If ValueIsFilled(RowData.ChoiceList) Then
			
			For Each SelectionListItem In RowData.ChoiceList Do
				Items.CalculationParameterTreeParameterValue.ChoiceList.Add(SelectionListItem.Value, SelectionListItem.Presentation);
			EndDo;
			
			Items.CalculationParameterTreeParameterValue.ListChoiceMode = True;
			
		Else
			
			Items.CalculationParameterTreeParameterValue.ListChoiceMode = False;
			
		EndIf;
		
		// Number format.
		If RowData.ValueType.ContainsType(Type("Number")) Then
			
			NumberType = RowData.ValueType.NumberQualifiers;
			
			If NumberType.AllowedSign = AllowedSign.Nonnegative And RowData.RangeWith = Undefined Then
				Items.CalculationParameterTreeParameterValue.MinValue = 0;
			EndIf;
			
			TextFormat = "ND=" + NumberType.Digits + "; NFD=" + NumberType.FractionDigits + "; NZ=0";
			
			Items.CalculationParameterTreeParameterValue.EditFormat = TextFormat;
			
		Else
			
			Items.CalculationParameterTreeParameterValue.EditFormat = "";
			
		EndIf;
		
	EndIf;
	
EndProcedure


&AtClient
Procedure CalculationParameterTreeParameterValueClearing(Item, StandardProcessing)
	
	RowData = Items.CalculationParameterTree.CurrentData;
	If RowData = Undefined Then
		Return;
	EndIf;
	
	If Item.ChoiceList.Count() > 0 Then
		StandardProcessing = False;
	Else
		RowData.Value = RowData.DefaultValue;
		RowData.ValueChanged = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculationParameterTreeParameterValueOnChange(Item)
	
	RowData = Items.CalculationParameterTree.CurrentData;
	If RowData = Undefined Then
		Return;
	EndIf;
	
	RowData.ValueChanged = (RowData.Value <> RowData.DefaultValue);
	
	FillInChangeFlagForParameterGroup(RowData.GetParent());
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	FontParameters = Items.CalculationParameterTreeDescription.Font;
	
	// Selection of rows with the changed parameter value.
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CalculationParameterTreeDescription.Name);
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CalculationParameterTreeParameterValue.Name);
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CalculationParameterTreeDefaultValue.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("CalculationParameterTree.IsFolder");
	ItemFilter.RightValue = False;
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("CalculationParameterTree.ValueChanged");
	ItemFilter.RightValue = True;
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	
	AppearanceItem.Appearance.SetParameterValue("Font", New Font(FontParameters,,, True));
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Red);
	
	// Highlighting groups of unchanged parameters.
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CalculationParameterTreeDescription.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("CalculationParameterTree.IsFolder");
	ItemFilter.RightValue = True;
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("CalculationParameterTree.ValueChanged");
	ItemFilter.RightValue = False;
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	
	AppearanceItem.Appearance.SetParameterValue("Font", New Font(FontParameters,, 12));
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Green);
	
	// Selection of groups of changed parameters.
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = AppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CalculationParameterTreeDescription.Name);
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("CalculationParameterTree.IsFolder");
	ItemFilter.RightValue = True;
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	
	ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("CalculationParameterTree.ValueChanged");
	ItemFilter.RightValue = True;
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	
	AppearanceItem.Appearance.SetParameterValue("Font", New Font(FontParameters,, 12));
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Red);
	
EndProcedure

&AtServer
Procedure FillInOperationParameters(SaveModifiedData = True)
	
	AllParameters = GetDataWarehouse();
	
	If SaveModifiedData Then
		RememberChangedParameters(AllParameters);
	EndIf;
	
	CalculationParameterTree.GetItems().Clear();
	PreviousOperation = Operation;
	
	If ValueIsFilled(AllParameters[Operation].DescriptionOfParameterGroups) Then
		
		// The parameters are grouped.
		For Each ParameterGroupDescription In AllParameters[Operation].DescriptionOfParameterGroups Do
			
			GroupDetails = ParameterGroupDescription; // Structure
			
			If GroupDetails.Hide Then
				Continue;
			EndIf;
			
			GroupRow = CalculationParameterTree.GetItems().Add();
			FillPropertyValues(GroupRow, GroupDetails);
			
			GroupRow.IsFolder = True;
			
			ParameterStrings = AllParameters[Operation].ParametersDetails.FindRows(New Structure("Parent", GroupDetails.Name));
			
			AddParameterStrings(GroupRow, ParameterStrings, AllParameters);
			
			FillInChangeFlagForParameterGroup(GroupRow);
			
		EndDo;
		
	Else
		
		// Parameters without groups.
		AddParameterStrings(CalculationParameterTree, AllParameters[Operation].ParametersDetails, AllParameters);
		
	EndIf;
		
	ParametersDetails = New ValueStorage(AllParameters, New Deflation(9));
	
EndProcedure

&AtServer
Procedure RememberChangedParameters(AllParameters)
	
	SynchronizedParameters = Constants.MonthEndClosingSettings.CreateValueManager().DescriptionOfSynchronizedOperationParameters();
	
	For Each ParameterString In CalculationParameterTree.GetItems() Do
		
		If ParameterString.IsFolder Then
			
			For Each SubordinateParameterString In ParameterString.GetItems() Do
				
				RememberChangedParameter(
					AllParameters,
					SynchronizedParameters,
					SubordinateParameterString.Name,
					SubordinateParameterString.Value);
				
			EndDo;
			
		Else
			
			RememberChangedParameter(
				AllParameters,
				SynchronizedParameters,
				ParameterString.Name,
				ParameterString.Value);
			
		EndIf;
		
	EndDo;
	
	Modified = False;
	
EndProcedure

&AtServer
Procedure RememberChangedParameter(AllParameters, SynchronizedParameters, NameParameters, ParameterValue)
	
	ParameterChanged = (AllParameters[PreviousOperation].ParameterValues[NameParameters] <> ParameterValue);
	
	If Not ParameterChanged Then
		Return;
	EndIf;
	
	AllParameters[PreviousOperation].ParameterValues[NameParameters] = ParameterValue; // let's remember the new parameter value
	
	ParameterString = SynchronizedParameters.Find(NameParameters, "Name");
	
	If ParameterString = Undefined Then
		Return;
	EndIf;
	
	For Each SynchronizedOperation In ParameterString.Operations Do
		
		If SynchronizedOperation <> PreviousOperation Then
			AllParameters[SynchronizedOperation].ParameterValues[NameParameters] = ParameterValue; // let's remember the new value of the synchronized parameter
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure AddParameterStrings(ParameterGroup, ParametersDetails, AllParameters)
	
	For Each ParameterDetails In ParametersDetails Do
		
		If ParameterDetails.Hide Then
			Continue;
		EndIf;
		
		ParameterString = ParameterGroup.GetItems().Add();
		FillPropertyValues(ParameterString, ParameterDetails);
		
		ParameterString.Value = AllParameters[Operation].ParameterValues[ParameterString.Name];
		
		ParameterString.ValueChanged = (ParameterString.Value <> ParameterString.DefaultValue);
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInChangeFlagForParameterGroup(ParameterGroup)
	
	If ParameterGroup = Undefined Then
		Return;
	EndIf;
	
	ParameterGroup.ValueChanged = False;
	
	For Each ParameterDetails In ParameterGroup.GetItems() Do
		
		If ParameterDetails.ValueChanged Then
			ParameterGroup.ValueChanged = True;
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SaveParameters()
	
	AllParameters = GetDataWarehouse();
	
	RememberChangedParameters(AllParameters);
	
	Constants.MonthEndClosingSettings.CreateValueManager().SaveAllParameters(AllParameters);
	
EndProcedure

&AtServer
Function GetDataWarehouse()
	
	DataWarehouseIsTyped = ParametersDetails; // ValueStorage
	Return DataWarehouseIsTyped.Get();
		
EndFunction

#EndRegion
