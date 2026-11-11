
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Formula = Parameters.Formula;
	SourceFormula = Parameters.Formula;
	
	Parameters.Property("ThisIsPriceCalculation", ThisIsPriceCalculation);
	Parameters.Property("StringFormula", StringFormula);
	Parameters.Property("ResultType", ResultType);
	If Parameters.Property("FunctionsFromCommonModule") Then
		FunctionsFromCommonModule = New FixedArray(Parameters.FunctionsFromCommonModule);
	EndIf;
	Parameters.Property("FormulaForCalculationInQuery", FormulaForCalculationInQuery);
	
	Parameters.Property("SavedSettingsObjectKey", SavedSettingsObjectKey);
	
	If Parameters.Property("EnableValue") Then
		EnableValue = Parameters.EnableValue;
	Else
		EnableValue = False;
	EndIf;
	
	OperandTreeAddress = Parameters.OperandsTree;
	// Loading the tree using custom settings for the output of non-current details and tabular parts.
	// Initialization of a fixed matching of operand values.
	LoadOperandTree(); 
	
	OperatorsTreeStorageAddress = Undefined;
	If Parameters.Property("Operators", OperatorsTreeStorageAddress) And IsTempStorageURL(OperatorsTreeStorageAddress) Then
		OperatorsTree = GetFromTempStorage(OperatorsTreeStorageAddress);
	Else
		OperatorsTree = ProcessingOfFormulas.GetStandardOperatorsTree();
	EndIf;
	ValueToFormAttribute(OperatorsTree, "Operators");
	
	If Parameters.Property("OperandsTitle") Then
		Items.OperandsGroup.Title = Parameters.OperandsTitle;
		Items.OperandsGroup.ToolTip = Parameters.OperandsTitle;
	EndIf;
	
	If Parameters.Property("NotUsePresentation") Then
		Items.Presentation.Visible = False;
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(
			Items,
			"OperandsTree",
			"ChangeRowSet",
			False);
	
	If Parameters.Property("Advanced") And Parameters.Advanced Then
		
		Advanced           = Parameters.Advanced;
		
		Presentation = ?(Find(Parameters.Presentation, "["),"", Parameters.Presentation);
		
		TMCommonUseClientServer.SetFormItemProperty(
			Items,
			"OK",
			"Title",
			NStr("vi = 'Đặt công thức tùy ý';
				|ru = 'Задать произвольную формулу';
				|en = 'Apply formula'; fa = 'Apply formula';
				|it = 'Imposta una formula arbitraria';
				|pl = 'Ustaw dowolną formułę';
				|tr = 'İsteğe bağlı formül belirle'"));
			
		EstablishExplanationOfOperands(ThisObject, Parameters.Filter);
		
		If EnableValue Then
			
			Parameters.Property("OperationalPlanningExplanationParameters", OperationalPlanningExplanationParameters);
			
			SetFormHeader(ThisObject, Parameters);
			
			SetOperandValueHeader();
			
			SetPresentationOfCalculationByFormula(Formula, OperandValues, Calculation);
			
		EndIf;
		
		RestoreSettings();
		
	EndIf;
	
	EstablishConditionalAppearanceOfOperatorsAndOperands();
	SetVisibility1();
	
	If Not ThisIsPriceCalculation
		Or UserRightsCached.PriceTypeApproval() Then
		
		Items.HintNoEditingAllowed.Visible = False;
		
	Else
		
		ReadOnly = True;
		
		Items.OK.Enabled = False;
		Items.Validate.Enabled = False;
		Items.Presentation.ReadOnly = True;
		
		Items.HintNoEditingAllowed.Title =
			New FormattedString(
				New FormattedString(PictureLib.Warning),
				New FormattedString(StringFunctionsClientServer.GenerateCharacterString(" ", 2)),
				New FormattedString(NStr("vi = 'Việc soạn công thức tính toán đơn giá không được phép đối với người sử dụng hiện tại.
					|Hãy liên hệ với người sử dụng có vai trò xác nhận dạng giá hoặc người quản trị.';
					|ru = 'Редактирование формул расчета цен недоступно для текущего пользователя.
					|Обратитесь к пользователю с ролью утверждения видов цен или администратору.';
					|en = 'Editing price calculation formulas is not available for the current user.
					|Contact a user with the ""Price type approval"" role or an administrator.'; fa = 'Editing price calculation formulas is not available for the current user.
					|Contact a user with the ""Price type approval"" role or an administrator.';
					|it = 'Editing price calculation formulas is not available for the current user.
					|Contact a user with the ""Price type approval"" role or an administrator.';
					|pl = 'Editing price calculation formulas is not available for the current user.
					|Contact a user with the ""Price type approval"" role or an administrator.';
					|tr = 'Mevcut kullanıcı için fiyat hesaplama formüllerini düzenleme olanağı kullanılamaz.
					|Fiyat türlerini onaylama rolü olan kullanıcıya veya yöneticiye başvurun.'"),,
					StyleColors.ToolTipTextColor));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If ForceCloseTheForm Then
		Return;
	EndIf;
	
	If Modified
		And ValueIsFilled(SourceFormula) And SourceFormula <> Formula Then
		
		Cancel = True;
		QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
						|ru = 'Данные были изменены. Сохранить изменения?';
						|en = 'The data has changed. Do you want to save the changes?'; fa = 'The data has changed. Do you want to save the changes?';
						|it = 'I dati sono stati modificati. Salvare le modifiche?';
						|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
						|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
		CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		ClearMessages();
		If ProcessingOfFormulasClient.CheckFormula(
				Formula,
				FormulaOperands(),
				ResultType,
				FormulaValidationParameters()) Then
			
			ForceCloseTheForm = True;
			If Advanced Then
				ShouldSaveSettings();
				Close(New Structure("Formula, Presentation, Calculation",Formula, Presentation, Calculation));
			Else
				Close(Formula);
			EndIf;
			
		EndIf;
		
	ElsIf QuestionResult = DialogReturnCode.No Then
		
		ForceCloseTheForm = True;
		Close(Undefined);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOperandsTree

&AtClient
Procedure OperandsTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.OperandsTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not CurrentData.OperandSelectionAllowed Then
		Return;
	EndIf;
	
	If Field.Name = "OperandsTreeValue"
		And CurrentData.ContainsValue
		And OperationalPlanningExplanationParameters <> Undefined Then
		StandardProcessing = False;
		Operand = CurrentData.FullRowID;
		ExecuteDecryption(Operand);
		
		Return;
	EndIf;
	
	If CurrentData.DeletionMark Then
		QueryText = NStr("vi = 'Đánh dấu xóa phần tử được chọn. Tiếp tục?';
						|ru = 'Выбранный элемент помечен на удаление. Продолжить?';
						|en = 'The selected item is marked for deletion. Continue?'; fa = 'The selected item is marked for deletion. Continue?';
						|it = 'Elemento selezionato è contrassegnato per la cancellazione. Continuare?';
						|pl = 'Wybrany element został zaznaczony do usunięcia. Kontynuować?';
						|tr = 'Seçilen öğe silinmek üzere işaretlendi. Devam edilsin mi?'");
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("CurDataFullID", CurrentData.FullRowID);
		AdditionalParameters.Insert("Mode", "Selection");
		CallbackDescription = New CallbackDescription("OperandTreeSelectionEndOfDragEnd", ThisObject, AdditionalParameters);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		StandardProcessing = False;
		Return;
	EndIf;
	
	InsertTextIntoFormula(ProcessingOfFormulasClientServer.GetOperandTextToInsert(CurrentData.FullRowID));
	
EndProcedure

&AtClient
Procedure OperandTreeSelectionEndOfDragEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.No
	   And AdditionalParameters.Mode = "Drag" Then
		
		BeginningOfTheLine  = 0;
		BeginningOfTheColumn = 0;
		EndOfRow   = 0;
		EndOfColumn  = 0;
		
		Items.Formula.GetTextSelectionBounds(BeginningOfTheLine, BeginningOfTheColumn, EndOfRow, EndOfColumn);
		Items.Formula.SelectedText = "";
		Items.Formula.SetTextSelectionBounds(BeginningOfTheLine, BeginningOfTheColumn, BeginningOfTheLine, BeginningOfTheColumn);
		
	ElsIf Result = DialogReturnCode.Yes
		And AdditionalParameters.Mode = "Selection" Then

		Id = AdditionalParameters.CurDataFullID;
		InsertTextIntoFormula(ProcessingOfFormulasClientServer.GetOperandTextToInsert(Id));
	EndIf;
	
EndProcedure

&AtClient
Procedure OperandsTreeBeforeExpand(Item, String, Cancel)
	
	CurrentData = OperandsTree.FindByID(String);
	If CurrentData.ExpandToAttributes
		And Not CurrentData.SubordinateRowsExpanded Then
		// If there are subordinate details and the details of the next level have not been received for them.
		ExpandSubordinateRowsOfOperandTree(String);
	EndIf;
	
EndProcedure

&AtServer
Procedure ExpandSubordinateRowsOfOperandTree(IDOfCurRowOfOperandTree)
	
	ProcessingOfFormulas.ExpandOperandStringOfFormTree(OperandsTree,
		IDOfCurRowOfOperandTree,
		MaximumRowExpansionLevel);
	
EndProcedure

&AtClient
Procedure OperandsTreeDragStart(Item, DragParameters, Perform)
	
	If DragParameters.Value = Undefined Then
		Return;
	EndIf;
	
	TreeRow = OperandsTree.FindByID(DragParameters.Value);
	If Not TreeRow.OperandSelectionAllowed Then
		Perform = False;
		Return;
	EndIf;
	
	DragParameters.Value = ProcessingOfFormulasClientServer.GetOperandTextToInsert(
		TreeRow.FullRowID);
	
EndProcedure

&AtClient
Procedure OperandsTreeDragEnd(Item, DragParameters, StandardProcessing)
	
	TreeRow = Item.CurrentData;
	
	If TreeRow.DeletionMark Then
		QueryText = NStr("vi = 'Đánh dấu xóa phần tử được chọn. Tiếp tục?';
						|ru = 'Выбранный элемент помечен на удаление. Продолжить?';
						|en = 'The selected item is marked for deletion. Continue?'; fa = 'The selected item is marked for deletion. Continue?';
						|it = 'Elemento selezionato è contrassegnato per la cancellazione. Continuare?';
						|pl = 'Wybrany element został zaznaczony do usunięcia. Kontynuować?';
						|tr = 'Seçilen öğe silinmek üzere işaretlendi. Devam edilsin mi?'");
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("CurDataFullID", TreeRow.FullRowID);
		AdditionalParameters.Insert("Mode", "Drag");
		CallbackDescription = New CallbackDescription("OperandTreeSelectionEndOfDragEnd", ThisObject, AdditionalParameters);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOperators

&AtClient
Procedure OperatorsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	RowData = Operators.FindByID(RowSelected);
	If RowData.IsFolder Then
		Return;
	EndIf;
	InsertOperatorIntoFormula();
	
EndProcedure

&AtClient
Procedure OperatorsDragStart(Item, DragParameters, StandardProcessing)
	
	CurrentData = Item.CurrentData;
	If Not CurrentData.IsFolder Then
		DragParameters.Value = Item.CurrentData.StructureToInsert;
	Else
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OperatorsDragEnd(Item, DragParameters, StandardProcessing)
	
	If Item.CurrentData.Id = "Format" Then
		RowFormat = New FormatStringWizard;
		CallbackDescription = New CallbackDescription("OperatorsDragEndCompletion",
		                                              ThisObject,
		                                              New Structure("RowFormat", RowFormat));
		RowFormat.Show(CallbackDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure OperatorsDragEndCompletion(Text, AdditionalParameters) Export
    
    RowFormat = AdditionalParameters.RowFormat;
    
    If ValueIsFilled(RowFormat.Text) Then
        TextForInsert = "Format( , """ + RowFormat.Text + """)";
        Items.Formula.SelectedText = TextForInsert;
    EndIf;

EndProcedure

&AtClient
Procedure OperatorsOnActivateRow(Item)
	CurrentData = Items.Operators.CurrentData;
	If Not CurrentData = Undefined Then
		CurrentOperatorNote = CurrentData.Explanation;
	Else
		CurrentOperatorNote = "";
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	
	If ProcessingOfFormulasClient.CheckFormula(Formula, FormulaOperands(), ResultType, FormulaValidationParameters()) Then
		
		ForceCloseTheForm = True;
		If Advanced Then
			ShouldSaveSettings();
			Close(New Structure("Formula, Presentation, Calculation",Formula, Presentation, Calculation));
		Else
			Close(Formula);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Validate(Command)
	
	ClearMessages();
	ProcessingOfFormulasClient.CheckFormulaInteractive(Formula,
		FormulaOperands(),
		ResultType,
		FormulaValidationParameters());
	
EndProcedure

#EndRegion

#Region Private

#Region Other



&AtClient
Procedure InsertTextIntoFormula(TextForInsert, Move = 0)
	
	RowStart = 0;
	RowEnd = 0;
	ColumnStart = 0;
	ColumnEnd = 0;
	
	Items.Formula.GetTextSelectionBounds(RowStart, ColumnStart, RowEnd, ColumnEnd);
	
	If (ColumnEnd = ColumnStart) And (ColumnEnd + StrLen(TextForInsert)) > Items.Formula.Width / 8 Then
		Items.Formula.SelectedText = "";
	EndIf;
		
	Items.Formula.SelectedText = TextForInsert;
	
	If Not Move = 0 Then
		Items.Formula.GetTextSelectionBounds(RowStart, ColumnStart, RowEnd, ColumnEnd);
		Items.Formula.SetTextSelectionBounds(RowStart, ColumnStart - Move, RowEnd, ColumnEnd - Move);
	EndIf;
		
	CurrentItem = Items.Formula;
	
	If Advanced Then
		Presentation = "";
	EndIf;
	
EndProcedure


&AtClient
Function FormulaOperands()
	
	ArrayOfOperands = ProcessingOfFormulasClientServer.OperandsOfTextFormula(Formula);
	
	// Search for fixed operands (for example, types of prices), as well as operands of the data path.
	// For operands - the path to the data, the check is searched only for the first part of the operand (up to the first point),
	// because further search is time-consuming.
	OperandsToDelete_ = New Array;
	For Each Operand In ArrayOfOperands Do
		CheckedPart = Operand;
		If AllowedOperands.Find(CheckedPart) = Undefined Then
			OperandParts = ProcessingOfFormulasClientServer.OperandParts(Operand);
			CheckedPart = OperandParts[0];
			If OperandParts.Count() > 1 Then
				CheckedPart = CheckedPart + ".";
			EndIf;
			If AllowedOperands.Find(CheckedPart) = Undefined Then
				OperandsToDelete_.Add(Operand);
			EndIf;
		EndIf;
	EndDo;
	For Each Operand In OperandsToDelete_ Do
		IndexOf = ArrayOfOperands.Find(Operand);
		While IndexOf <> Undefined Do
			ArrayOfOperands.Delete(IndexOf);
			IndexOf = ArrayOfOperands.Find(Operand);
		EndDo;
		
		ErrorText = NStr("vi = 'Không tìm thấy toán hạng ""[%1]""';
						|ru = 'Не найден операнд ""[%1]""';
						|en = 'The ""[%1]"" operand is not found'; fa = 'The ""[%1]"" operand is not found';
						|it = 'Operando ""[%1]"" non trovato';
						|pl = 'Nie znaleziono operandu ""[%1]""';
						|tr = 'İşlenen ""[%1]"" bulunamadı'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Operand);
		CommonClient.MessageToUser(ErrorText);
	EndDo;
	
	Return ArrayOfOperands;
	
EndFunction

&AtClient
Procedure InsertOperatorIntoFormula()
	
	If Items.Operators.CurrentData.Id = "Format" Then
		RowFormat = New FormatStringWizard;
		CallbackDescription = New CallbackDescription("InsertOperatorIntoFormulaCompletion",
		                                              ThisObject,
		                                              New Structure("RowFormat", RowFormat));
		RowFormat.Show(CallbackDescription);
		Return;
	Else	
		InsertTextIntoFormula(Items.Operators.CurrentData.StructureToInsert,
		                      Items.Operators.CurrentData.Move);
	EndIf;
	
	InsertOperatorIntoFragmentFormula();
EndProcedure

&AtClient
Procedure InsertOperatorIntoFormulaCompletion(Text, AdditionalParameters) Export
	
	RowFormat = AdditionalParameters.RowFormat;
	
	If ValueIsFilled(RowFormat.Text) Then
		TextForInsert = "Format( , """ + RowFormat.Text + """)";
		InsertTextIntoFormula(TextForInsert, Items.Operators.CurrentData.Move);
	Else
		InsertTextIntoFormula(Items.Operators.CurrentData.StructureToInsert,
		                      Items.Operators.CurrentData.Move);
	EndIf;
	
	InsertOperatorIntoFragmentFormula();

EndProcedure

&AtClient
Procedure InsertOperatorIntoFragmentFormula()
	
	If Advanced Then
		CurrentData = Items.Operators.CurrentData;
		If ValueIsFilled(CurrentData.StructureToInsert) Then
			Parent = CurrentData.GetParent();
			If Not Parent = Undefined
				And (Parent.Id = "FormulaExamples"
					Or Parent.Id = "LatestUsedFormulas") Then
				Presentation = CurrentData.Presentation;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure FormulaOnChange(Item)
	
	If Advanced Then
		Presentation = "";
	EndIf;
	
	If EnableValue Then
		SetPresentationOfCalculationByFormula(Formula, OperandValues, Calculation);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibility1()

	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"OperandsTreeValue",
		"Visible",
		EnableValue);
		
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"Calculation",
		"Visible",
		EnableValue);
		
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"DecorationAutoSum",
		"Visible",
		EnableValue);
		
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"Operators",
		"Header",
		EnableValue);
	
EndProcedure

// Set the representation of the calculation according to the formula.
// 
// Parameters:
//  Calculation_Formula - String - Calculation Formula
//  OperandValues - FixedMap - Operand values
//  Calculation - String - Calculation
&AtClientAtServerNoContext
Procedure SetPresentationOfCalculationByFormula(Val Calculation_Formula, OperandValues, Calculation)
	
	If Not ValueIsFilled(Calculation_Formula) Then
		Calculation = "";
		Return;
	EndIf;
	
	Calculation_Formula = RemovingInsignificantCharacters(Calculation_Formula);
	
	ArrayOfOperands = ProcessingOfFormulasClientServer.OperandsOfTextFormula(Calculation_Formula);
	
	For Each Operand In ArrayOfOperands Do
		OperandValue = OperandValues.Get(Operand);
		If Not OperandValue = Undefined Then
			Calculation_Formula = StrReplace(Calculation_Formula, "["+Operand+"]", Format(OperandValue, "NDS=.; NZ=0; NG=0"));
		EndIf;
	EndDo;
	
	Try
		#If Client Then
			CalculationResult = Format(Eval(Calculation_Formula),"ND=15; NFD=3; NZ=0");
		#Else
			CalculationResult = Format(Common.CalculateInSafeMode(Calculation_Formula),"ND=15; NFD=3; NZ=0");
		#EndIf
	Except
		Return;
	EndTry;
	
	Calculation = "= " + CalculationResult;
	
	Calculation = RemovingInsignificantCharacters(Calculation);
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	If IsBlankString(SavedSettingsObjectKey) Then
		Return;
	EndIf;
	
	ArrayOfFormulas = Undefined;
	
	NumberOfStoredFormulas = 10;
	
	SetSettingValue("ArrayOfFormulas", ArrayOfFormulas);
	
	NewArrayOfFormulas = New ValueTable();
	NewArrayOfFormulas.Columns.Add("Presentation");
	NewArrayOfFormulas.Columns.Add("Formula");
	
	Formula = RemovingInsignificantCharacters(Formula);
	Presentation = RemovingInsignificantCharacters(Presentation);
	
	If Not ValueIsFilled(Formula) Then
		Return;
	EndIf;
	
	If TypeOf(ArrayOfFormulas) = Type("ValueTable") And ArrayOfFormulas.Count() > 0 Then
		
		FoundRow = ArrayOfFormulas.Find(Formula, "Formula");
		
		NewValue = NewArrayOfFormulas.Add();
		NewValue.Presentation = Presentation;
		
		If FoundRow = Undefined Then
			NewValue.Formula = Formula;
		Else
			NewValue.Formula = FoundRow.Formula;
			ArrayOfFormulas.Delete(FoundRow);
		EndIf;
		
		For Each Item In ArrayOfFormulas Do
			NewValue = NewArrayOfFormulas.Add();
			FillPropertyValues(NewValue,Item);
			
			NumberOfStoredFormulas = NumberOfStoredFormulas - 1;
			
			If NumberOfStoredFormulas <=0 Then
				Break;
			EndIf;
			
		EndDo; 
		
	Else
		
		NewValue = NewArrayOfFormulas.Add();
		NewValue.Presentation = Presentation;
		NewValue.Formula		= Formula;
		
	EndIf;
	
	Common.CommonSettingsStorageSave(SavedSettingsObjectKey, "ArrayOfFormulas", NewArrayOfFormulas);
	
EndProcedure

&AtServer
Procedure RestoreSettings()
	
	If IsBlankString(SavedSettingsObjectKey) Then
		Return;
	EndIf;
	
	ArrayOfFormulas = Undefined;
	
	SetSettingValue("ArrayOfFormulas", ArrayOfFormulas);
	
	OperatorsTree = FormAttributeToValue("Operators");
	
	If TypeOf(ArrayOfFormulas) = Type("ValueTable") And ArrayOfFormulas.Count() > 0 Then
		GroupPresentation = NStr("vi = 'Công thức được sử dụng gần nhất';
								|ru = 'Последние используемые формулы';
								|en = 'Latest used formulas'; fa = 'Latest used formulas';
								|it = 'Ultime formule utilizzabili';
								|pl = 'Ostatnie używane formuły';
								|tr = 'Son kullanılan formüller'");
		OperatorsGroup = ProcessingOfFormulas.AddOperatorsGroup(OperatorsTree,
		                                                             "LatestUsedFormulas",
		                                                             GroupPresentation);
	Else
		Return;
	EndIf;
	
	For Each Item In ArrayOfFormulas Do
		OperatorPresentation = ?(ValueIsFilled(Item.Presentation),Item.Presentation,Item.Formula);
		ProcessingOfFormulas.AddOperator(OperatorsGroup, Item.Formula, Item.Formula, OperatorPresentation);
	EndDo;
	
	ValueToFormAttribute(OperatorsTree, "Operators");
	
EndProcedure

&AtServer
Procedure SetSettingValue(SettingName, Setting)
	
	SettingValueFromStorage = Common.CommonSettingsStorageLoad(SavedSettingsObjectKey, SettingName);
	If SettingValueFromStorage <> Undefined Then
		Setting = SettingValueFromStorage;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function RemovingInsignificantCharacters(Val IncomingString)
	
	IncomingString = TrimAll(IncomingString);
	StringLength = StrLen(IncomingString);
	EndString = String("");
	
	While StringLength > 0 Do 
		
		FirstChar = Left(IncomingString, 1);
		
		If Not IsBlankString(FirstChar) Then
			EndString = EndString + FirstChar;
			StringLength = StringLength - 1;
			Indent = 2;
		Else
			EndString = EndString + " ";
			IncomingString = TrimL(IncomingString);
			StringLength = StrLen(IncomingString);
			Indent = 1;
		EndIf;
		
		If StringLength > 1 Then
			IncomingString = Mid(IncomingString, Indent, StringLength);
		Else
			EndString = EndString + Mid(IncomingString, Indent, 1);
			StringLength = 0; 
		EndIf;
		
	EndDo;
	
	Return EndString;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetFormHeader(Form, Parameters)

	Form.AutoTitle= False;
	Form.Title = NStr("vi = 'Chỉnh sửa công thức cho ""';
						|ru = 'Редактирование формулы для ""';
						|en = 'Edit the formula for ""'; fa = 'Edit the formula for ""';
						|it = 'Modifica della formula per ""';
						|pl = 'Edycja formuły dla ""';
						|tr = '"" için formülün düzenlenmesi'") + Parameters.ValueHeader + """";

EndProcedure

&AtClientAtServerNoContext
Procedure EstablishExplanationOfOperands(Form, Filter)
	
	ElementExplanation = Form.Items.DecorationNote;
	ExplanationText = "";
	Font = New Font(,,,True);
	
	ThereIs_Warehouse								= Filter.Property("FilterWarehouse") And ValueIsFilled(Filter.FilterWarehouse);
	ThereIsSalesDivision				= Filter.Property("FilterSalesDivision") And ValueIsFilled(Filter.FilterSalesDivision);
	ThereIsPurchasingDivision				= Filter.Property("FilterPurchaseDepartment") And ValueIsFilled(Filter.FilterPurchaseDepartment);
	ThereIsDivisionDispatcher				= Filter.Property("FilterProductionDispatcherBusinessUnit") And ValueIsFilled(Filter.FilterProductionDispatcherBusinessUnit);
	ThereIsDivisionOfInternalConsumption 	= Filter.Property("FilterInternalConsumptionDepartment") 
		And ValueIsFilled(Filter.FilterInternalConsumptionDepartment);
	ThereIsDivision = ThereIsSalesDivision Or ThereIsPurchasingDivision Or ThereIsDivisionDispatcher 
		Or ThereIsDivisionOfInternalConsumption;
	ThereIsAPartner								= Filter.Property("FilterPartner") And ValueIsFilled(Filter.FilterPartner);
	ThereIsAgreement 							= Filter.Property("FilterTerms") And ValueIsFilled(Filter.FilterTerms);
	ThereIsStoreFormat						= Filter.Property("FilterStoreFormat") And ValueIsFilled(Filter.FilterStoreFormat);
	ThereIsAppointment							= Filter.Property("FilterPurpose");
	
	If ThereIs_Warehouse Then
		ExplanationText = New FormattedString(ExplanationText,
														New FormattedString(NStr("vi = 'kho bãi';
																				|ru = 'складу';
																				|en = 'warehouse'; fa = 'انبار';
																				|it = 'magazzino';
																				|pl = 'magazynu';
																				|tr = 'ambara'") + " ",
														"""",
														New FormattedString(String(Filter.FilterWarehouse), Font),
														""""));
	EndIf;
	
	If ThereIsStoreFormat Then
		ExplanationText = New FormattedString(ExplanationText,
														New FormattedString(NStr("vi = 'khuôn dạng cửa hàng';
																				|ru = 'формату магазина';
																				|en = 'store format'; fa = 'قالب فروشگاه';
																				|it = 'formato del negozio';
																				|pl = 'formatu magazynu';
																				|tr = 'mağaza formatı'") + " ",
														"""",
														New FormattedString(String(Filter.FilterStoreFormat), Font),
														""""));
	EndIf;
	
	If ThereIsSalesDivision Then
		ExplanationText = New FormattedString(ExplanationText,
														?(ThereIs_Warehouse Or ThereIsStoreFormat,", ",""),
														New FormattedString(NStr("vi = 'bộ phận bán hàng';
																				|ru = 'подразделению продажи';
																				|en = 'sales business unit'; fa = 'sales business unit';
																				|it = 'reparto vendite';
																				|pl = 'działu sprzedaży';
																				|tr = 'satış departmanına'") + " ",
														"""",New FormattedString(String(Filter.FilterSalesDivision), Font),""""));
	EndIf;
	
	If ThereIsPurchasingDivision Then
		ExplanationText = New FormattedString(ExplanationText,
														?(ThereIs_Warehouse Or ThereIsStoreFormat,", ",""),
														New FormattedString(NStr("vi = 'bộ phận mua hàng';
																				|ru = 'подразделению закупки';
																				|en = 'purchase business unit'; fa = 'purchase business unit';
																				|it = 'reparto acquisti';
																				|pl = 'działu zakupów';
																				|tr = 'satın alımlar departmanına'") + " ",
														"""",New FormattedString(String(Filter.FilterPurchaseDepartment), Font),""""));
	EndIf;
	
	If ThereIsDivisionDispatcher Then
		ExplanationText = New FormattedString(ExplanationText,
														?(ThereIs_Warehouse Or ThereIsStoreFormat,", ",""),
														New FormattedString(NStr("vi = 'bộ phận điều khiển';
																				|ru = 'подразделению диспетчеру';
																				|en = 'dispatching unit'; fa = 'dispatching unit';
																				|it = 'Reparto-dispatcher';
																				|pl = 'działu dystrybucyjnego';
																				|tr = 'üretim kontrolü departmanına'") + " ",
														"""",New FormattedString(String(Filter.FilterProductionDispatcherBusinessUnit), Font),""""));
	EndIf;
	
	If ThereIsDivisionOfInternalConsumption Then
		ExplanationText = New FormattedString(ExplanationText,
			?(ThereIs_Warehouse Or ThereIsStoreFormat,", ",""),
			New FormattedString(NStr("vi = 'bộ phận tiêu dùng nội bộ';
									|ru = 'подразделению внутренних потреблений';
									|en = 'business unit of inventory consumption'; fa = 'business unit of inventory consumption';
									|it = 'reparto di consumi interni';
									|pl = 'do działa konsumpcji wewnętrznych';
									|tr = 'stok tüketimi departmanına'") + " ",
			"""",New FormattedString(String(Filter.FilterInternalConsumptionDepartment), Font),""""));
	EndIf;
	
	If ThereIsAPartner Then
		ExplanationText = New FormattedString(ExplanationText,
														?(ThereIs_Warehouse Or ThereIsStoreFormat Or ThereIsDivision,", ",""),
														New FormattedString(NStr("vi = 'bạn hàng';
																				|ru = 'партнеру';
																				|en = 'partner'; fa = 'شریک تجاری';
																				|it = 'Partner';
																				|pl = 'partnera';
																				|tr = 'iş ortağı'") + " ",
														"""", New FormattedString(String(Filter.FilterPartner), Font),""""));
	EndIf;
	
	If ThereIsAgreement Then
		ExplanationText = New FormattedString(ExplanationText,
														?(ThereIs_Warehouse Or ThereIsStoreFormat Or ThereIsDivision Or ThereIsAPartner,", ",""),
														New FormattedString(NStr("vi = 'thỏa thuận';
																				|ru = 'соглашению';
																				|en = 'agreement'; fa = 'agreement';
																				|it = 'accordo';
																				|pl = 'porozumienia';
																				|tr = 'anlaşmaya'") + " ",
														"""", New FormattedString(String(Filter.FilterTerms), Font),""""));
	EndIf;
	
	If ThereIsAppointment Then
		ExplanationText = New FormattedString(ExplanationText,
														?(ThereIs_Warehouse Or ThereIsStoreFormat Or ThereIsDivision Or ThereIsAPartner Or ThereIsAgreement,", ",""),
														New FormattedString(NStr("vi = 'chỉ định';
																				|ru = 'назначению';
																				|en = 'assignment'; fa = 'assignment';
																				|it = 'per assegnazione';
																				|pl = 'przeznaczenia';
																				|tr = 'atama'") + " ",
														"""", New FormattedString(?(ValueIsFilled(Filter.FilterPurpose), String(Filter.FilterPurpose),NStr("vi = 'Không chỉ định';
																																							|ru = 'Без назначения';
																																							|en = 'Without appointment'; fa = 'Without appointment';
																																							|it = 'Senza assegnazione';
																																							|pl = 'Bez przeznaczenia';
																																							|tr = 'Atamasız'")), Font),""""));
	EndIf;
	
	ElementExplanation.Visible = ValueIsFilled(ExplanationText);
	
	ExplanationText = New FormattedString(NStr("vi = '* Các trường lọc theo';
												|ru = '* Поля с отбором по';
												|en = '* Fields with the filter by'; fa = '* Fields with the filter by';
												|it = '* Campo con selezione per';
												|pl = '* Pola z wyborem wg';
												|tr = '* Filtreli alan kapsamındaki'") + " ", ExplanationText, ".");
	
	ElementExplanation.Title = ExplanationText;
	
EndProcedure

&AtClient
Procedure ExecuteDecryption(Operand)
	
	OperandsWithDecoding = GetOperandsWithDecryption();
	
	If Not OperandsWithDecoding.Property(Operand) Then
		Return;
	EndIf;
	
	Array_SetNames = New Array();
	Array_SetNames.Add(Operand);
	
	DecryptionDataArray = GetDecryption(Array_SetNames);
	
	If DecryptionDataArray = Undefined Then
		Return;
	EndIf; 
	
	DocumentsList = New ValueList();
	
	For Each DetailsItem In DecryptionDataArray Do
	
		DocumentPresentation = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = '%1 (số %2 ngày %3)';
										|ru = '%1 (№ %2 от %3)';
										|en = '%1 (No. %2 from %3)'; fa = '%1 (No. %2 from %3)';
										|it = '%1 (№%2 del %3)';
										|pl = '%1 (Nr %2 z %3)';
										|tr = '%1 ( %3 tarihli %2 numaralı)'"),
										Format(DetailsItem[Operand], "NFD=3"), DetailsItem.DocumentNumber, 
										Format(DetailsItem.DocumentDate, "DLF=D"));
				
		DocumentsList.Add(DetailsItem.Document, DocumentPresentation);
	
	EndDo;
	If DocumentsList.Count() = 0 Then
		Return;
	EndIf;
	NameOfDecryptionForm = OperandsWithDecoding[Operand] + ".ObjectForm";
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("NameOfDecryptionForm",NameOfDecryptionForm);
	
	CallbackDescription = New CallbackDescription("DocumentSelection", ThisObject,AdditionalParameters);
	DocumentsList.ShowChooseItem(CallbackDescription, NStr("vi = 'Chọn chứng từ';
															|ru = 'Выберите документ';
															|en = 'Select document'; fa = 'انتخاب سند';
															|it = 'Selezionare documento';
															|pl = 'Wybierz dokument';
															|tr = 'Belgeyi seçin'"));
	
EndProcedure

&AtClient
Procedure DocumentSelection(SelectionResult, AdditionalParameters) Export 

	If Not SelectionResult = Undefined Then 
		
		Document = SelectionResult.Value;
		ShowValue(, Document);
		
	EndIf;

EndProcedure 

&AtServer
Function GetOperandsWithDecryption()

	OperandsWithDecoding = New Structure();
	
	For Each Field In OperationalPlanningExplanationParameters.Fields Do
		Value = Field.Value;
		If Value.Property("Details") And ValueIsFilled(Value.Details) Then
			OperandsWithDecoding.Insert(Field.Value.Name,Field.Value.Details);
		EndIf;
	EndDo;
	
	Return OperandsWithDecoding;

EndFunction

&AtServer
Function GetDecryption(Array_SetNames)

	Return Planning.GetDecryption(Array_SetNames, OperationalPlanningExplanationParameters);

EndFunction

&AtClientAtServerNoContext
Function RecalculateBeginningOfPeriod(BeginOfPeriod, Periodicity, Val Offset)
	
	Result = TMCommonUseClientServer.CalculatePeriodEndDate(BeginOfPeriod, Periodicity, Offset);
	
	Result = PlanningClientServerCached.CalculateStartDateOfPeriod(Result + 1, Periodicity);
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function RecalculateEndOfPeriod(BeginOfPeriod, Periodicity, Val Offset)
	
	Result = TMCommonUseClientServer.CalculatePeriodEndDate(BeginOfPeriod, Periodicity, Offset);
	
	Result = PlanningClientServerCached.CalculatePeriodEndDate(Result + 1, Periodicity);
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function CreatePeriodPresentation(Periodicity, BeginOfPeriod,PeriodEnding) 

	Presentation = "";
	
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		CurrentSessionDate = CurrentSessionDate();
	#Else 
		CurrentSessionDate = CommonClient.SessionDate();
	#EndIf
		
	PlanningClientServer.SetStartEndOfPlanPeriod(Periodicity, BeginOfPeriod, PeriodEnding, CurrentSessionDate);
	
	If Periodicity = PredefinedValue("Enum.Periodicity.Month") Then
		
		If BegOfMonth(BeginOfPeriod) = BegOfMonth(PeriodEnding) Then
			Presentation = Format(BeginOfPeriod, NStr("vi = 'ДФ=''ММММ гггг''';
														|ru = 'ДФ=''ММММ гггг''';
														|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
														|it = 'ДФ=''ММММ гггг''';
														|pl = 'DF=''MMMM yyyy''';
														|tr = 'DF=''MMMM yyyy'''"));
		Else
			Presentation = Format(BeginOfPeriod, NStr("vi = 'ДФ=''ММММ гггг''';
														|ru = 'ДФ=''ММММ гггг''';
														|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
														|it = 'ДФ=''ММММ гггг''';
														|pl = 'DF=''MMMM yyyy''';
														|tr = 'DF=''MMMM yyyy'''")) + " - " 
							+ Format(PeriodEnding, NStr("vi = 'ДФ=''ММММ гггг''';
														|ru = 'ДФ=''ММММ гггг''';
														|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
														|it = 'ДФ=''ММММ гггг''';
														|pl = 'DF=''MMMM yyyy''';
														|tr = 'DF=''MMMM yyyy'''"));
		EndIf;
		
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Day") Then
		
		If BegOfDay(BeginOfPeriod) = BegOfDay(PeriodEnding) Then
			Presentation = Format(BeginOfPeriod, "DLF=DD");
		Else
			Presentation = Format(BeginOfPeriod, "DLF=DD") + " - " + Format(PeriodEnding, "DLF=DD");
		EndIf;
		
	Else
		
		Presentation = Format(BeginOfPeriod, "DLF=DD") + " - " + Format(PeriodEnding, "DLF=DD");
		
	EndIf;
	
	Return Presentation;

EndFunction

&AtServer
Procedure SetOperandValueHeader()

	If Not OperationalPlanningExplanationParameters.Property("OffsetPeriodStart")
		Or OperationalPlanningExplanationParameters.Property("EndOfOffsetPeriod") Then
		Return;
	EndIf;
	
	BeginOfPeriod 		= RecalculateBeginningOfPeriod(OperationalPlanningExplanationParameters.OffsetPeriodStart,
		OperationalPlanningExplanationParameters.Periodicity,
		OperationalPlanningExplanationParameters.PeriodOffset);
	PeriodEnding 	= RecalculateEndOfPeriod(OperationalPlanningExplanationParameters.OffsetPeriodEnd,
		OperationalPlanningExplanationParameters.Periodicity,
		OperationalPlanningExplanationParameters.PeriodOffset);
	
	SamplePeriod_ 		= CreatePeriodPresentation(OperationalPlanningExplanationParameters.Periodicity,
		BeginOfPeriod, PeriodEnding);
	
	TitleText = NStr("vi = 'Giá trị (%1)';
					|ru = 'Значение (%1)';
					|en = 'Value (%1)'; fa = 'Value (%1)';
					|it = 'Valore (%1)';
					|pl = 'Wartość (%1)';
					|tr = 'Değer (%1)'");
	TitleText = StrTemplate(TitleText, SamplePeriod_);
	Items.OperandsGroup.Title = TitleText;

EndProcedure

&AtServer
Procedure LoadOperandTree()

	Tree = GetFromTempStorage(OperandTreeAddress);
	
	If TypeOf(Tree) <> Type("ValueTree") Then
		Return;
	EndIf;
	
	OperandsWithValues = New Map();
	ArrayOfAllowedOperands = New Array;
	ProcessingOfFormulas.LoadOperandTreeIntoTreeOfForm(OperandsTree,
		Tree,
		ArrayOfAllowedOperands,
		OperandsWithValues);
	AllowedOperands = New FixedArray(ArrayOfAllowedOperands);
	OperandValues = New FixedMap(OperandsWithValues);
	
	TypesOfAllowedOperands = New Map();
	For Each Operand In ArrayOfAllowedOperands Do
		String = Tree.Rows.Find(Operand, "Id", True);
		If String <> Undefined Then
			TypesOfAllowedOperands.Insert(Operand, String.ValueType);
		EndIf;
	EndDo;
	TypesOfOperands = New FixedMap(TypesOfAllowedOperands);
	
EndProcedure

&AtClient
Function FormulaValidationParameters()
	
	CheckParameters = ProcessingOfFormulasClient.FormulaValidationParameters();
	CheckParameters.FormulaForCalculationInQuery = FormulaForCalculationInQuery;
	If ValueIsFilled(FunctionsFromCommonModule) Then
		CheckParameters.CommonModuleFunctions = FunctionsFromCommonModule;
	EndIf;
	CheckParameters.Field = "Formula";
	CheckParameters.TypesOfOperands = TypesOfOperands;
	
	Return CheckParameters;
	
EndFunction

&AtServer
Procedure EstablishConditionalAppearanceOfOperatorsAndOperands()
	SetConditionalAppearanceOfOperators();
	SetConditionalAppearanceOfOperands();
EndProcedure

// Parameters:
// 	Typability Perechislennye.Typeability Is Undefined - 
&AtServer
Procedure SetConditionalAppearanceOfOperators()
	
	// If the operator tree row is a group, then the identifier is not shown.
	AppearanceItem = ConditionalAppearance.Items.Add();
	AppearanceItem.Use = True;
	
	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("Operators.IsFolder");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = True;
	FilterElement.Use = True;
	
	AppearanceItem.Appearance.SetParameterValue("Visible", False);
	VisibilityParameter = New DataCompositionParameter("Visible");
	For Each DesignParameter In AppearanceItem.Appearance.Items Do
		If DesignParameter.Parameter = VisibilityParameter Then
			DesignParameter.Use = True;
		EndIf;
	EndDo;
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Use = True;
	AppearanceField.Field =  New DataCompositionField(Items.OperatorsId.Name);
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfOperands()
	
EndProcedure



#EndRegion

#EndRegion
