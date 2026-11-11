
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If ValueIsFilled(Object.Ref) Then
		Set = InformationRegisters.NonMonetaryItemsValues.CreateRecordSet();
		Set.Filter.Factor.Set(Object.Ref);
		Set.Read();
		IndicatorValues_2 = Set.Unload();
		ValueToFormAttribute(IndicatorValues_2,"ValueSet");
	EndIf;
	
	RefreshFormTitle();
	BufferNames = Object.Description;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	LineNumber = 1;
	For Each Page1 In ValueSet Do
		
		If Not ValueIsFilled(Page1.Period) Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Thiếu ngày bắt đầu của giá trị trong hàng số%1';
					|ru = 'Не указана дата начала действия значения в строке №%1';
					|en = 'Value effective date is not specified in line No. %1'; fa = 'Value effective date is not specified in line No. %1';
					|it = 'La data di inizio della validità del valore nella riga №%1 non è indicata';
					|pl = 'Nie podano daty rozpoczęcia działania wartości w wierszu nr %1';
					|tr = '№%1 satırında değerin başlangıç tarihi belirtilmedi'"),
				LineNumber);
			CommonClientServer.MessageToUser(
				Text,
				Object.Ref,
				CommonClientServer.PathToTabularSection("ValueSet", LineNumber, "Period"),
				,
				Cancel);
		EndIf;
		If Not ValueIsFilled(Page1.Author) Then
			Page1.Author = Users.CurrentUser();
		EndIf;
	    LineNumber = LineNumber + 1;
	EndDo;
	RefreshFormTitle();
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	Set = InformationRegisters.NonMonetaryItemsValues.CreateRecordSet();
	Set.Filter.Factor.Set(Object.Ref);
	IndicatorValues_2 = FormAttributeToValue("ValueSet");
	IndicatorValues_2.FillValues(Object.Ref,"Factor");
	Set.Load(IndicatorValues_2);
	Set.Write();

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_NonMonetaryItem", , Object.Ref);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionOnChange(Item)
	
	If BufferNames = Object.NameForPrinting Or IsBlankString(Object.NameForPrinting) Then
		Object.NameForPrinting = Object.Description;
	EndIf;
	BufferNames = Object.Description;
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersValueSet

&AtClient
Procedure ValueSetOnStartEdit(Item, NewRow, Copy)
	
	If NewRow And Not Copy Then
		TableRow = Items.ValueSet.CurrentData;
		TableRow.Period = CommonClient.SessionDate();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ValueSetOrganization.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ValueSet.Organization");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Sử dụng cho mọi người>';
													|ru = '<Использовать для всех>';
													|en = '<Use for all>'; fa = '<Use for all>';
													|it = '<Usare per tutti>';
													|pl = '<Używaj dla wszystkich>';
													|tr = '<Tümü için kullan>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ValueSetDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ValueSet.Department");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Sử dụng cho mọi người>';
													|ru = '<Использовать для всех>';
													|en = '<Use for all>'; fa = '<Use for all>';
													|it = '<Usare per tutti>';
													|pl = '<Używaj dla wszystkich>';
													|tr = '<Tümü için kullan>'"));

EndProcedure

#Region Other

&AtServer
Procedure RefreshFormTitle()
	
	TypePresentation = NStr("vi = 'Chỉ tiêu phi tiền tệ';
							|ru = 'Немонетарный показатель';
							|en = 'Non-monetary item'; fa = 'قلم غیرپولی';
							|it = 'Indice non monetario';
							|pl = 'Wskaźnik niemonetarny';
							|tr = 'Gayrinakdi gösterge'");
	If Not ValueIsFilled(Object.Ref) Then
		ThisForm.Title = TypePresentation + " (" + NStr("vi = 'tạo';
														|ru = 'создание';
														|en = 'create'; fa = 'ایجاد';
														|it = 'creazione';
														|pl = 'create';
														|tr = 'oluşturma'") + ")";
	Else
		ThisForm.Title = Object.NameForPrinting + " (" + TypePresentation + ")";
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
