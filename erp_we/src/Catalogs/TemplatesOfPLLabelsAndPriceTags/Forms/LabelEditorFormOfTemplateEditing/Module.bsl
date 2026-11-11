#Region Variables

&AtClient
Var NumberOfPixelsPerMillimeter; // The number of millimeters contained in 1 pixel at the current resolution.
&AtClient
Var OneMillimeterWide; // The number of units of width measurement, which is contained in one millimeter at the current resolution.
&AtClient
Var OneMillimeterOfHeight; // The number of units of height measurement, which is contained in one millimeter at the current resolution.
&AtClient
Var CloseForm; // Flag that allows closing the form. The truth - form will be closed. False - the form will not be closed.
&AtClient
Var TemplateChanged; // Flag, marking the modification of the layout.

#EndRegion

#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	CloseForm = False;
	
	#If WebClient Then
		
		OneMillimeterWide = 0.535;
		OneMillimeterOfHeight = 2.711;
		Items.ToolTip.Title = "";
		
	#Else
	
		Etalon = GetReferenceTemplate();
		
		Drawing = Etalon.Drawings[0];
		FigureHeight = Drawing.Height;
		LineHeightInMillimeters = Drawing.Top;
		ColumnWidthInMillimeters = Drawing.Left;
		RowHeight	= Etalon.Area("R1").RowHeight;
		ColumnWidth_1	= Etalon.Area("C1").ColumnWidth;
		
		NumberOfPixelsPerMillimeter = 100 / FigureHeight;
		OneMillimeterWide = ColumnWidth_1 / ColumnWidthInMillimeters;
		OneMillimeterOfHeight = RowHeight / LineHeightInMillimeters;
	
	#EndIf
	
	Template.Area().AutoRowHeight = False;	
	Template.Area().RowHeight = OneMillimeterOfHeight;
	Template.Area().ColumnWidth = OneMillimeterWide;
	
	Orientation = 0;
	GridStep = 1;
	If Not ValueIsFilled(CallbackDescriptionOnClose.AdditionalParameters.XMLTemplateDetails) Then
		TemplateChanged = False;
		StandardDimensions = "30:20";
		LabelWidth_ = 30;
		LabelHeight = 20;
		UpdateLabelSizes();
	Else
		XMLTemplateDetails = CallbackDescriptionOnClose.AdditionalParameters.XMLTemplateDetails;
		FillAccordingToTemplateData();
	EndIf;
	
	SetAvailabilityAndVisibilityOfFieldChangeElements(False);
	
	PrintPLLabelsAndPriceTagsClientOverridable.LabelEditorFormOfEditingTemplateWhenOpening(ThisForm, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If CloseForm Then
		Return;
	EndIf;
	
	If Exit Then
		
		Cancel = True;
	Else
		
		If TemplateChanged Then
			Cancel = True;
			ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), NStr("vi = 'Đóng mà không lưu?';
																							|ru = 'Закрыть без сохранения?';
																							|en = 'Close without saving?'; fa = 'Close without saving?';
																							|it = 'Chiudere senza salvare?';
																							|pl = 'Zamknąć bez zapisywania?';
																							|tr = 'Kaydetmeden kapatılsın mı?'"), QuestionDialogMode.YesNo);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("DCSStorageAddress") Then
		DCSStorageAddress = Parameters.DCSStorageAddress;
	EndIf;
	
	If Parameters.Property("AddressOfTemplate") And Not Parameters.AddressOfTemplate = "" Then
		AddressOfTemplate = Parameters.AddressOfTemplate; 
		Template = GetFromTempStorage(AddressOfTemplate);
	EndIf;
	
	PrintPLLabelsAndPriceTagsOverridable.LabelEditorFormOfEditingTemplateWhenCreatingOnServer(ThisObject, Cancel, Parameters, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CleaningField(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SizeWhenChanging(Item)
	
	ChooseStandardSize();
	RedrawTemplate();
	
EndProcedure

&AtClient
Procedure StandardDimensionsOnChange(Item)
	
	If ValueIsFilled(StandardDimensions) Then
		
		Substring = Left(StandardDimensions, Find(StandardDimensions, ":")-1);
		LabelWidth_ = Number(Substring);
		Substring = Mid(StandardDimensions, Find(StandardDimensions, ":")+1);
		LabelHeight = Number(Substring);
		RedrawTemplate();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WidthTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	Quotient = Number(Text)/GridStep;
	If Int(Quotient) <> Quotient Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure HeightTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	Quotient = Number(Text)/GridStep;
	If Int(Quotient) <> Quotient Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure GridStepClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure GridStepChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueSelected<>GridStep Then
		
		NewGridStep = ValueSelected;
		
		FieldProjections = GetFieldProjections(NewGridStep);
		
		AbolishedFields = New Array; //Array of SeeGetFieldProjections
		
		IndexOf = 0;
		
		For Each CurField In FieldProjections Do
			
			If CurField.Type<>"UserData"
				And (CurField.Right-CurField.Left+1<NewGridStep/2
				Or CurField.Bottom-CurField.Top+1<NewGridStep/2) Then
				AbolishedFields.Add(CurField);
				FieldProjections.Delete(IndexOf);
			EndIf;
			
			IndexOf = IndexOf + 1;
			
		EndDo;
		
		If AbolishedFields.Count()>0 Then
			
			StandardProcessing = False;
			
			StringFieldsToDelete = "%LineBreak%";
			FieldsToDelete__ = New Array;
			
			For Each CurrentField In AbolishedFields Do
				CurField = CurrentField; // Structure
				StringFieldsToDelete = StringFieldsToDelete + CurField.Value + "%LineBreak%";
				FieldsToDelete__.Add(CurField.Id);
			EndDo;
			
			StringQuestion = NStr("vi = 'Trường:%Fields%có kích thước quá nhỏ.%LineBreak%Tiếp tục thay đổi khoảng cách lưới, sau khi xóa các trường đã chỉ định?';
									|ru = 'Поля:%Fields%имеют слишком маленькие размеры.%LineBreak%Продолжить изменение шага сетки, удалив указанные поля?';
									|en = 'Fields:%Fields% are too small.%LineBreak%Continue changing the grid step by deleting the specified fields?'; fa = 'Fields:%Fields% are too small.%LineBreak%Continue changing the grid step by deleting the specified fields?';
									|it = 'I campi %Fields% hanno dimensioni troppo piccole. %LineBreak% Continuare la modifica dello spazio della griglia eliminando i campi indicati?';
									|pl = 'Pola:%Fields%mają zbyt małe rozmiary.%LineBreak%Usunąć wskazane pola i kontynuować zmianę kroku siatki?';
									|tr = 'Alan: %Fields% alanının ebatları çok küçük.%LineBreak%Belirtilen alanları silerek ağ adımlarını değiştirmeye devam edilsin mi?'");
			StringQuestion = StrReplace(StringQuestion, "%Fields%", StringFieldsToDelete);
			StringQuestion = StrReplace(StringQuestion, "%LineBreak%", Chars.LF);
			
			ShowQueryBox(New CallbackDescription("ProcessUserSDecision", ThisObject, New Structure("FieldProjections, NewGridStep, FieldsToDelete__", FieldProjections, NewGridStep, FieldsToDelete__)), StringQuestion, QuestionDialogMode.YesNo);
			
		Else
			ApplyNewCoordinates(FieldProjections, NewGridStep);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LayoutWhenTheAreaIsActivated(Item)
	
	FoundRows = Fields.FindRows(New Structure("Description", Template.CurrentArea.Name));
	
	If FoundRows.Count() > 0 Then
		
		SD = FoundRows[0];
		SetCaptionsForBorders(SD);
		
		SetAvailabilityAndVisibilityOfFieldChangeElements(True, SD.Type);
		
	Else
		SetAvailabilityAndVisibilityOfFieldChangeElements(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure TemplateSelection(Item, Area, StandardProcessing)
	
	Description = Area.Name;
	FoundFields = Fields.FindRows(New Structure("Description", Description));
	
	If FoundFields.Count()>0 Then
		StartEditingField(FoundFields[0]);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddAField(Command)
	
	StartAddingField();
	
EndProcedure

&AtClient
Procedure ChangeTheField(Command)
	
	FoundRows = Fields.FindRows(New Structure("Description", Items.Template.CurrentArea.Name));
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];
		StartEditingField(SD);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RemoveField(Command)
	
	FoundRows = Fields.FindRows(New Structure("Description", Items.Template.CurrentArea.Name));
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];
		DeleteFieldDescription(SD.Description);
		ClearArea((SD.Top-1)/GridStep+1, (SD.Left-1)/GridStep+1, SD.Bottom/GridStep, SD.Right/GridStep);
		SetAvailabilityAndVisibilityOfFieldChangeElements(False);
		TemplateChanged = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadFromFile(Command)
	
	#If WebClient Then
		CallbackDescription = New CallbackDescription("StartDownloadingFromFile", ThisObject);
		CheckAvailabilityOfFileExtension(CallbackDescription, True);
	#Else
		// In thin and thick clients, the extension is always connected.
		StartDownloadingFromFile(True, Undefined);
	#EndIf
	
EndProcedure

&AtClient
Procedure SaveToFile(Command)
	
	#If WebClient Then
		CallbackDescription = New CallbackDescription("StartSavingToFile", ThisObject);
		CheckAvailabilityOfFileExtension(CallbackDescription, True);
	#Else
		// In thin and thick clients, the extension is always connected.
		StartSavingToFile(True, Undefined);
	#EndIf
EndProcedure

&AtClient
Procedure ClearTemplate(Command)
	
	If Fields.Count()>0 Then
		ShowQueryBox(New CallbackDescription("ClearTemplateCompletion", ThisObject), NStr("vi = 'Xóa khuôn in?';
																							|ru = 'Очистить макет?';
																							|en = 'Clear template?'; fa = 'Clear template?';
																							|it = 'Cancellare layout?';
																							|pl = 'Oczyścić szablon?';
																							|tr = 'Şablon temizlensin mi?'"), QuestionDialogMode.YesNo);
	Else
		ClearingTemplate();
		TemplateChanged = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReceiveTemplateDescriptionInXML(Command)
	
	#If Not MobileAppClient And Not MobileClient Then
	SD = New TextDocument;
	XMLText = GetTextWithLabelDescription();
	SD.SetText(XMLText);
	SD.Show();
	#EndIf
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	CloseForm = True;
	CallbackDescriptionOnClose.AdditionalParameters.Insert("TemplateSize", String(LabelWidth_) + "x" + String(LabelHeight));
	CallbackDescriptionOnClose.AdditionalParameters.Insert("XMLTemplateDetails", SaveXMLFile());
	CallbackDescriptionOnClose.AdditionalParameters.Insert("Fields", GenerateListOfFields());
	CallbackDescriptionOnClose.AdditionalParameters.Insert("Template", PutToTempStorage(Template, New UUID));
	Close(DialogReturnCode.OK);
	
EndProcedure

&AtClient
Procedure OutsideBorder(Command)
	
	StringSearchStructure = TheStructureOfTheSearch();
	StringSearchStructure.Description = Items.Template.CurrentArea.Name;
	FoundRows = Fields.FindRows(StringSearchStructure);
	
	If FoundRows.Count()>0 Then
		SD = FoundRows[0];//See TheStructureOfTheSearch
		ChangeFieldBoundaries(SD.Description, 5);
		SetFormattingButtonMarkings();
	EndIf;
	
EndProcedure

&AtClient
Procedure TopBorder(Command)
	
	StringSearchStructure = TheStructureOfTheSearch();
	StringSearchStructure.Description = Items.Template.CurrentArea.Name;
	FoundRows = Fields.FindRows(StringSearchStructure);
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];//See TheStructureOfTheSearch
		ChangeFieldBoundaries(SD.Description, 2);
		
		Items.TopBorder.Check = Not Items.TopBorder.Check;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LeftBorder(Command)
	
	StringSearchStructure = TheStructureOfTheSearch();
	StringSearchStructure.Description = Items.Template.CurrentArea.Name;
	FoundRows = Fields.FindRows(StringSearchStructure);
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];//See TheStructureOfTheSearch
		ChangeFieldBoundaries(SD.Description, 1);
		
		Items.LeftBorder.Check = Not Items.LeftBorder.Check;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BottomBorder(Command)
	
	StringSearchStructure = TheStructureOfTheSearch();
	StringSearchStructure.Description = Items.Template.CurrentArea.Name;
	FoundRows = Fields.FindRows(StringSearchStructure);
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];//See TheStructureOfTheSearch
		ChangeFieldBoundaries(SD.Description, 4);
		
		Items.BottomBorder.Check = Not Items.BottomBorder.Check;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RightBorder(Command)
	
	StringSearchStructure = TheStructureOfTheSearch();
	StringSearchStructure.Description = Items.Template.CurrentArea.Name;
	FoundRows = Fields.FindRows(StringSearchStructure);
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];//See TheStructureOfTheSearch
		ChangeFieldBoundaries(SD.Description, 3);
		
		Items.RightBorder.Check = Not Items.RightBorder.Check;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MoveTheLeftBorderToTheLeft(Command)
	
	StringSearchStructure = TheStructureOfTheSearch();
	StringSearchStructure.Description = Items.Template.CurrentArea.Name;
	FoundRows = Fields.FindRows(StringSearchStructure);
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];//See TheStructureOfTheSearch
		
		If SD.Type <> "UserData" Then
			ChangeBorderCoordinate(SD.Description, 1, -GridStep);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MoveTheLeftBorderToTheRight(Command)
	
	StringSearchStructure = TheStructureOfTheSearch();
	StringSearchStructure.Description = Items.Template.CurrentArea.Name;
	FoundRows = Fields.FindRows(StringSearchStructure);
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];//See TheStructureOfTheSearch
		
		If SD.Type <> "UserData" Then
			ChangeBorderCoordinate(SD.Description, 1, GridStep);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MoveTheRightBorderToTheLeft(Command)
	
	StringSearchStructure = TheStructureOfTheSearch();
	StringSearchStructure.Description = Items.Template.CurrentArea.Name;
	FoundRows = Fields.FindRows(StringSearchStructure);
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];//See TheStructureOfTheSearch
		
		If SD.Type <> "UserData" Then
			ChangeBorderCoordinate(SD.Description, 3, -GridStep);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MoveTheRightBorderToTheRight(Command)
	
	StringSearchStructure = TheStructureOfTheSearch();
	StringSearchStructure.Description = Items.Template.CurrentArea.Name;
	FoundRows = Fields.FindRows(StringSearchStructure);
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];//See TheStructureOfTheSearch
		
		If SD.Type <> "UserData" Then
			ChangeBorderCoordinate(SD.Description, 3, GridStep);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure IncreaseUpperBound(Command)
	
	StringSearchStructure = TheStructureOfTheSearch();
	StringSearchStructure.Description = Items.Template.CurrentArea.Name;
	FoundRows = Fields.FindRows(StringSearchStructure);
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];//See TheStructureOfTheSearch
		
		If SD.Type <> "UserData" Then
			ChangeBorderCoordinate(SD.Description, 2, -GridStep);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DecreaseUpperBound(Command)
	
	StringSearchStructure = TheStructureOfTheSearch();
	StringSearchStructure.Description = Items.Template.CurrentArea.Name;
	FoundRows = Fields.FindRows(StringSearchStructure);
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];//See TheStructureOfTheSearch
		
		If SD.Type <> "UserData" Then
			ChangeBorderCoordinate(SD.Description, 2, GridStep);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure IncreaseLowerBound(Command)
	
	StringSearchStructure = TheStructureOfTheSearch();
	StringSearchStructure.Description = Items.Template.CurrentArea.Name;
	FoundRows = Fields.FindRows(StringSearchStructure);
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];//See TheStructureOfTheSearch
		
		If SD.Type <> "UserData" Then
			ChangeBorderCoordinate(SD.Description, 4, -GridStep);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DecreaseLowerBound(Command)
	
	StringSearchStructure = TheStructureOfTheSearch();
	StringSearchStructure.Description = Items.Template.CurrentArea.Name;
	FoundRows = Fields.FindRows(StringSearchStructure);
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];//See TheStructureOfTheSearch
		
		If SD.Type <> "UserData" Then
			ChangeBorderCoordinate(SD.Description, 4, GridStep);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AlignLeft(Command)
	
	FoundRows = Fields.FindRows(New Structure("Description", Items.Template.CurrentArea.Name));
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];
		
		If SD.Type = "Text" Then
			
			SetHorizontalPositionOfText(SD, "Left");
			
			Items.AlignLeft.Check = True;
			Items.AlignCenter.Check = False;
			Items.AlignRight.Check = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AlignCenter(Command)
	
	FoundRows = Fields.FindRows(New Structure("Description", Items.Template.CurrentArea.Name));
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];
		
		If SD.Type = "Text" Then
			
			SetHorizontalPositionOfText(SD, "Center");
			
			Items.AlignLeft.Check = False;
			Items.AlignCenter.Check = True;
			Items.AlignRight.Check = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AlignRight(Command)
	
	FoundRows = Fields.FindRows(New Structure("Description", Items.Template.CurrentArea.Name));
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];
		
		If SD.Type = "Text" Then
			
			SetHorizontalPositionOfText(SD, "Right");
			
			Items.AlignLeft.Check = False;
			Items.AlignCenter.Check = False;
			Items.AlignRight.Check = True;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TopAlign(Command)
	
	FoundRows = Fields.FindRows(New Structure("Description", Items.Template.CurrentArea.Name));
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];
		
		If SD.Type = "Text" Then
			
			SetVerticalPositionOfText(SD, "Top");
			
			Items.TopAlign.Check = True;
			Items.SetVerticalAlignmentToCenter.Check = False;
			Items.BottomAlign.Check = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetVerticalAlignmentToCenter(Command)
	
	FoundRows = Fields.FindRows(New Structure("Description", Items.Template.CurrentArea.Name));
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];
		
		If SD.Type = "Text" Then
			
			SetVerticalPositionOfText(SD, "Center");
			
			Items.TopAlign.Check = False;
			Items.SetVerticalAlignmentToCenter.Check = True;
			Items.BottomAlign.Check = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BottomAlign(Command)
	
	FoundRows = Fields.FindRows(New Structure("Description", Items.Template.CurrentArea.Name));
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];
		
		If SD.Type = "Text" Then
			
			SetVerticalPositionOfText(SD, "Bottom");
			
			Items.TopAlign.Check = False;
			Items.SetVerticalAlignmentToCenter.Check = False;
			Items.BottomAlign.Check = True;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Bold(Command)
	
	FoundRows = Fields.FindRows(New Structure("Description", Items.Template.CurrentArea.Name));
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];
		
		If SD.Type = "Text" Then
			
			ChangeFont(SD, 1);
			
			Items.Bold.Check = Not Items.Bold.Check;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Italics(Command)
	
	FoundRows = Fields.FindRows(New Structure("Description", Items.Template.CurrentArea.Name));
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];
		
		If SD.Type = "Text" Then
			
			ChangeFont(SD, 2);
			
			Items.Italics.Check = Not Items.Italics.Check;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Underscore(Command)
	
	FoundRows = Fields.FindRows(New Structure("Description", Items.Template.CurrentArea.Name));
	
	If FoundRows.Count()>0 Then
		
		SD = FoundRows[0];
		
		If SD.Type = "Text" Then
			
			ChangeFont(SD, 3);			
			
			Items.Underscore.Check = Not Items.Underscore.Check;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RemoveLimits(Command)
	
	StringSearchStructure = TheStructureOfTheSearch();
	StringSearchStructure.Description = Items.Template.CurrentArea.Name;
	FoundRows = Fields.FindRows(StringSearchStructure);
	
	If FoundRows.Count()>0 Then
		SD = FoundRows[0];//See TheStructureOfTheSearch
		ChangeFieldBoundaries(SD.Description, 0);
		SetFormattingButtonMarkings();
	EndIf;
	
EndProcedure

&AtClient
Procedure EditAdditionalData(Command)
	
	TransmittedParameters = New Structure;
	
	ArrayOfAdditionalDataFields = New Array;
	
	For Each CurField In Fields Do
		
		If CurField.Type = "UserData" Then
			DescriptionOfAdditionalDataField = New Structure;
			DescriptionOfAdditionalDataField.Insert("Description",			CurField.Description);
			DescriptionOfAdditionalDataField.Insert("Type",					CurField.Type);
			DescriptionOfAdditionalDataField.Insert("PopulationType",			CurField.PopulationType);
			DescriptionOfAdditionalDataField.Insert("DefaultValue",	CurField.DefaultValue);
			DescriptionOfAdditionalDataField.Insert("Value",				CurField.Value);
			DescriptionOfAdditionalDataField.Insert("Top",					Undefined);
			DescriptionOfAdditionalDataField.Insert("Left",					Undefined);
			DescriptionOfAdditionalDataField.Insert("Bottom",					Undefined);
			DescriptionOfAdditionalDataField.Insert("Right",					Undefined);
			DescriptionOfAdditionalDataField.Insert("Orientation",			Undefined);
			DescriptionOfAdditionalDataField.Insert("Font",					Undefined);
			DescriptionOfAdditionalDataField.Insert("LeftFrame",			Undefined);
			DescriptionOfAdditionalDataField.Insert("TopFrame",			Undefined);
			DescriptionOfAdditionalDataField.Insert("RightFrame",			Undefined);
			DescriptionOfAdditionalDataField.Insert("BottomFrame",			Undefined);
			DescriptionOfAdditionalDataField.Insert("BorderType",				Undefined);
			DescriptionOfAdditionalDataField.Insert("FrameWidth",			Undefined);
			DescriptionOfAdditionalDataField.Insert("BarcodeType",			Undefined);
			DescriptionOfAdditionalDataField.Insert("SignatureFontSize",	Undefined);
			DescriptionOfAdditionalDataField.Insert("BarcodeLabel",		Undefined);
			DescriptionOfAdditionalDataField.Insert("CheckCharacter",		Undefined);
			DescriptionOfAdditionalDataField.Insert("HorizontalPosition",Undefined);
			DescriptionOfAdditionalDataField.Insert("VerticalPosition",	Undefined);
			DescriptionOfAdditionalDataField.Insert("Multiline",		Undefined);
			DescriptionOfAdditionalDataField.Insert("Format",				CurField.Format);
			
			ArrayOfAdditionalDataFields.Add(DescriptionOfAdditionalDataField);
		EndIf;
		
	EndDo;
	
	TransmittedParameters.Insert("Fields", ArrayOfAdditionalDataFields);
	TransmittedParameters.Insert("GridStep", GridStep);
	
	NotificationOnCompletion = New CallbackDescription("EditAdditionalDataCompletion", ThisObject, TransmittedParameters);
	OpenForm("Catalog.TemplatesOfPLLabelsAndPriceTags.Form.LabelEditorAdditionalData", New Structure("DCSStorageAddress", DCSStorageAddress),,,,, NotificationOnCompletion);
	
EndProcedure

&AtClient
Procedure EditDCS(Command)
	
	HandlerNotifications = New CallbackDescription("ProcessingOpeningOfDCSSettings", ThisObject);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("DCSStorageAddress", DCSStorageAddress);
	OpeningParameters.Insert("UUID", UUID);
	OpeningParameters.Insert("HandlerNotifications", HandlerNotifications);
	
	PrintPLLabelsAndPriceTagsClientOverridable.EditDCS(OpeningParameters);
	
EndProcedure
#EndRegion

#Region Private

&AtClient
Procedure FillAccordingToTemplateData(ReadingFromFile = False)
	
	#If Not MobileAppClient And Not MobileClient Then
	TextDocument = New TextDocument; 
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TextDocument", TextDocument); 
	CallbackDescription = New CallbackDescription("FillAccordingToTemplateDataCompletion", ThisObject, AdditionalParameters);
	
	If ReadingFromFile Then
		TextDocument.BeginReading(CallbackDescription, FileName);
	Else
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("XMLTemplateDetails", XMLTemplateDetails);
		FillAccordingToTemplateDataCompletion(AdditionalParameters);
	EndIf;
	#EndIf
	
EndProcedure

&AtServerNoContext
Function GetDescriptionOfTemplateOnServer(Val Source, ErrorMessage, ContentsOfXMLFile)
	
	Return PeripheralsLabelPrintersServer.GetTemplateDescription(Source, ErrorMessage, ContentsOfXMLFile);
	
EndFunction

&AtClient
Procedure FillAccordingToTemplateDataCompletion(AdditionalParameters) Export
	
	MessageText = "";
	ContentsOfXMLFile = Undefined; // Structure
	
	If AdditionalParameters.Property("TextDocument") Then
		
		Source = AdditionalParameters.TextDocument.GetText();
		
	ElsIf AdditionalParameters.Property("XMLTemplateDetails") Then
		
		Source = AdditionalParameters.XMLTemplateDetails;
		
	Else
		
		MessageText = StrReplace(MessageText, "%ErrorDescription%", FileName);
		CommonCELClient.MessageToUser(MessageText); 
		Return
		
	EndIf;
	
	ErrorMessage = "";
	
	If GetDescriptionOfTemplateOnServer(Source, ErrorMessage, ContentsOfXMLFile) Then
	
		GridStep = ContentsOfXMLFile.Scale;
		ClearArea(1, 1, LabelHeight/GridStep, LabelWidth_/GridStep);
		Fields.Clear();
		LabelWidth_ = ContentsOfXMLFile.Width;
		LabelHeight = ContentsOfXMLFile.Height;
		Orientation = ContentsOfXMLFile.Orientation;
		
		For Each CurField In ContentsOfXMLFile.Fields Do
			
			NewField = Fields.Add();
			FillPropertyValues(NewField, CurField);
			
			If CurField.Type="Text" Or CurField.Type="UserData" Then
				NewField.Presentation = CurField.Value;
			ElsIf CurField.Type="Barcode" Then
				FieldPresentation = StrTemplate(NStr("vi = 'Mã vạch %1';
													|ru = 'Штрихкод %1';
													|en = 'Barcode %1'; fa = 'Barcode %1';
													|it = 'Codice a barre %1';
													|pl = 'Kod kreskowy: %1';
													|tr = 'Barkod %1'"), String(CurField.BarcodeType));
				NewField.Presentation = FieldPresentation;
			ElsIf CurField.Type="Image" Then
				NewField.Presentation = NStr("vi = 'Hình ảnh';
											|ru = 'Картинка';
											|en = 'Picture'; fa = 'تصویر';
											|it = 'Картинка';
											|pl = 'Obraz';
											|tr = 'Resim'");
			EndIf;
			
			If CurField.Type<>"UserData" Then
				SaveFieldDesign(NewField, True);
			EndIf;
			
		EndDo;
		
	Else
		CommonCELClient.MessageToUser(ErrorMessage);
	EndIf;
	
	ChooseStandardSize();
	UpdateLabelSizes();
	TemplateChanged = False;
	
EndProcedure

&AtClient
Function GenerateListOfFields()
	
	Result = New Array;
	
	For Each CurField In Fields Do
		
		NewField = New Structure;
		NewField.Insert("Description", CurField.Description);
		NewField.Insert("Type", CurField.Type);
		NewField.Insert("PopulationType", CurField.PopulationType);
		NewField.Insert("Value", CurField.Value);
		NewField.Insert("DefaultValue", CurField.DefaultValue);
		NewField.Insert("Format", CurField.Format);
		Result.Add(NewField);
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Function GetTextWithLabelDescription()
	
	Result = SaveXMLFile();
	
	Return Result;
	
EndFunction

&AtClient
Procedure ChooseStandardSize()
	
	FoundItem = Items.StandardDimensions.ChoiceList.FindByValue(String(LabelWidth_) + ":" + String(LabelHeight));
	
	If FoundItem<>Undefined Then
		StandardDimensions = FoundItem.Value;
	Else
		StandardDimensions = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure StartEditingField(Field, SelectedDCSField=Undefined)
	
	FieldDetails = New Structure;
	FieldDetails.Insert("Description",			Field.Description);
	FieldDetails.Insert("Type",					Field.Type);
	FieldDetails.Insert("PopulationType",			Field.PopulationType);
	FieldDetails.Insert("DefaultValue",	Field.DefaultValue);
	FieldDetails.Insert("Value",				?(SelectedDCSField<>Undefined, SelectedDCSField, Field.Value));
	FieldDetails.Insert("Top",					Field.Top-1);
	FieldDetails.Insert("Left",					Field.Left-1);
	FieldDetails.Insert("Bottom",					Field.Bottom);
	FieldDetails.Insert("Right",					Field.Right);
	FieldDetails.Insert("Orientation",				Field.Orientation);
	FieldDetails.Insert("Font",					New Font(Field.FontName, ?(ValueIsFilled(Field.FontSize), Field.FontSize, Undefined), Field.Fatty, Field.Italic, Field.Underline, Field.Strikeout));
	FieldDetails.Insert("LeftFrame",				Field.LeftFrame);
	FieldDetails.Insert("TopFrame",			Field.TopFrame);
	FieldDetails.Insert("RightFrame",			Field.RightFrame);
	FieldDetails.Insert("BottomFrame",				Field.BottomFrame);
	FieldDetails.Insert("BorderType",				?(ValueIsFilled(Field.BorderType), Field.BorderType, "Solid"));
	FieldDetails.Insert("FrameWidth",			?(ValueIsFilled(Field.FrameWidth), Field.FrameWidth, 1));
	FieldDetails.Insert("BarcodeType",			?(ValueIsFilled(Field.BarcodeType), Field.BarcodeType, "EAN8"));
	FieldDetails.Insert("SignatureFontSize",	?(ValueIsFilled(Field.SignatureFontSize), Field.SignatureFontSize, 3));
	FieldDetails.Insert("BarcodeLabel",		Field.BarcodeLabel);
	FieldDetails.Insert("CheckCharacter",		Field.CheckCharacter);
	FieldDetails.Insert("HorizontalPosition",	?(ValueIsFilled(Field.HorizontalPosition), Field.HorizontalPosition, "Left"));
	FieldDetails.Insert("VerticalPosition",	?(ValueIsFilled(Field.VerticalPosition), Field.VerticalPosition, "Top"));
	FieldDetails.Insert("Multiline",		Field.Multiline);
	FieldDetails.Insert("Format",					Field.Format); 
	FieldDetails.Insert("Background",					Field.Background);
	FieldDetails.Insert("PictureSize",			?(ValueIsFilled(Field.PictureSize), Field.PictureSize, "Stretch"));
	
	FieldToEdit = New Structure;
	FieldToEdit.Insert("Description",	Field.Description);
	FieldToEdit.Insert("Type",			Field.Type);
	FieldToEdit.Insert("Top",			Field.Top);
	FieldToEdit.Insert("Left",			Field.Left);
	FieldToEdit.Insert("Bottom",			Field.Bottom);
	FieldToEdit.Insert("Right",			Field.Right);
	
	TransmittedParameters = New Structure;
	TransmittedParameters.Insert("FieldDetails", FieldDetails);
	TransmittedParameters.Insert("FieldToEdit", FieldToEdit);
	TransmittedParameters.Insert("GridStep", GridStep);
	
	NotificationOnCompletion = New CallbackDescription("StartAddingEditingCompletionField", ThisObject, TransmittedParameters);
	OpenForm("Catalog.TemplatesOfPLLabelsAndPriceTags.Form.LabelEditorFormOfTemplateFieldEditing", New Structure("DCSStorageAddress", DCSStorageAddress),,,,, NotificationOnCompletion);
	
EndProcedure

&AtClient
Procedure StartAddingEditingCompletionField(Result, TransmittedParameters) Export
	
	If Result = DialogReturnCode.OK Then
		
		FieldToEdit = Undefined;
		CleanUpOldDesign = False;
		FieldDetails = TransmittedParameters.FieldDetails;
		
		If FieldDetails.Type <> "UserData" Then
			FieldDetails.Left = ?(FieldDetails.Left>LabelWidth_, LabelWidth_, FieldDetails.Left);
			FieldDetails.Top = ?(FieldDetails.Top>LabelHeight, LabelHeight, FieldDetails.Top);
			FieldDetails.Right = ?(FieldDetails.Right>LabelWidth_, LabelWidth_, FieldDetails.Right);
			FieldDetails.Bottom = ?(FieldDetails.Bottom>LabelHeight, LabelHeight, FieldDetails.Bottom);
		EndIf;
		
		If TransmittedParameters.Property("FieldToEdit", FieldToEdit) Then
			
			If FieldToEdit.Type<>"UserData" Then
				
				CleanUpOldDesign = True;
				
				FieldToEdit.Left = FieldToEdit.Left;
				FieldToEdit.Top = FieldToEdit.Top;
				FieldToEdit.Right = FieldToEdit.Right;
				FieldToEdit.Bottom = FieldToEdit.Bottom;
				
			EndIf;
			
		EndIf;
		
		For Each CurField In Fields Do
			
			If (CurField.Description = FieldDetails.Description) And Not (FieldToEdit<>Undefined And FieldToEdit.Description = FieldDetails.Description) Then
				PromptUserToContinueEditingEnd(FieldDetails, FieldToEdit);
				Return;
			EndIf;
			
		EndDo;
		
		If FieldDetails.Type <> "UserData" Then
			
			IntersectingFields = New Array;
			
			For Each CurField In Fields Do
				
				If CurField.Type<>"UserData" Then
					
					HorizontalIntersection = False;
					
					If ((CurField.Left<=FieldDetails.Left And FieldDetails.Left<=CurField.Right) Or (CurField.Left<=FieldDetails.Right And FieldDetails.Right<=CurField.Right))
							Or ((FieldDetails.Left<=CurField.Left And CurField.Left<=FieldDetails.Right) Or (FieldDetails.Left<=CurField.Right And CurField.Right<=FieldDetails.Right)) Then
						HorizontalIntersection = True;
					EndIf;
						
					If HorizontalIntersection Then
						
						VerticalIntersection = False;
						
						If ((CurField.Top<=FieldDetails.Top And FieldDetails.Top<=CurField.Bottom) Or (CurField.Top<=FieldDetails.Bottom And FieldDetails.Bottom<=CurField.Bottom))
							Or ((FieldDetails.Top<=CurField.Top And CurField.Top<=FieldDetails.Bottom) Or (FieldDetails.Top<=CurField.Bottom And CurField.Bottom<=FieldDetails.Bottom)) Then
							VerticalIntersection = True;
						EndIf;
					
						If VerticalIntersection Then
							
							If FieldToEdit<>Undefined Then
								
								If FieldToEdit.Description = CurField.Description Then
									Continue;
								EndIf;
								
							EndIf;
							
							If CurField.Type = "Image" Then
								FieldPresentation = NStr("vi = 'Hình ảnh';
														|ru = 'Картинка';
														|en = 'Picture'; fa = 'تصویر';
														|it = 'Immagine';
														|pl = 'Obraz';
														|tr = 'Resim'");
							Else
								FieldPresentation = CurField.Value;
							EndIf;
							
							NewFieldDescription = New Structure;
							NewFieldDescription.Insert("Top", CurField.Top);
							NewFieldDescription.Insert("Left", CurField.Left);
							NewFieldDescription.Insert("Bottom", CurField.Bottom);
							NewFieldDescription.Insert("Right", CurField.Right);
							NewFieldDescription.Insert("Description", CurField.Description);
							NewFieldDescription.Insert("Presentation",FieldPresentation);
							
							IntersectingFields.Add(NewFieldDescription);
							
						EndIf;
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
			If IntersectingFields.Count()>0 Then
				TransmittedParameters.Insert("IntersectingFields", IntersectingFields);
				TransmittedParameters.Insert("CleanUpOldDesign", CleanUpOldDesign);
				InterrogateUserAboutDeletingIntersectingFields(TransmittedParameters);
				Return;
			EndIf;
			
		EndIf;
		
		TemplateChanged = True;
		
		If CleanUpOldDesign Then
			ClearArea((FieldToEdit.Top-1)/GridStep+1, (FieldToEdit.Left-1)/GridStep+1, FieldToEdit.Bottom/GridStep, FieldToEdit.Right/GridStep);
		EndIf;
		
		SaveFieldDescription(FieldDetails, FieldToEdit);
		
		If FieldDetails.Type<>"UserData" Then
			SaveFieldDesign(FieldDetails);
			Items.Template.CurrentArea = Template.Area(FieldDetails.Description);
		EndIf;
		
		SetAvailabilityAndVisibilityOfFieldChangeElements(True, FieldDetails.Type);
		
	EndIf;	
	
EndProcedure

// Fills in the list of parameters.
// 
// Parameters:
// 	SourceCollection - Array - source array.
// 	DestinationCollection - Array - the array receiver.
&AtClient
Procedure FillInListOfParameters(SourceCollection, DestinationCollection)
	
	For Each CurItem In SourceCollection Do
		
		DestinationCollection.Add(CurItem.Field);
		
		If CurItem.Items.Count()>0 Then
			FillInListOfParameters(CurItem.Items, DestinationCollection);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure DeleteFieldDescription(AreaName)
	
	Filter = New Structure("Description", AreaName);
	FoundField = Fields.FindRows(Filter);
	
	If FoundField.Count()>0 Then
		Fields.Delete(FoundField[0]);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearArea(Top, Left, Bottom, Right)
	
	#If WebClient Then
		
		ClearAreaOnServer(Top, Left, Bottom, Right);
		
	#Else
	
		Area = Template.Area(Top, Left, Bottom, Right);
		Area.Name = "";
		Area.Picture = Undefined;
		Area.UndoMerge();
		Area.Clear(True, True, True);	
		Area.BackColor = New Color(255,255,255);
	
	#EndIf
	
EndProcedure

&AtClient
Procedure SelectingFile()
	
	// APK: 1348-off the filesystem Client module from BSP is not used
	DOF = New FileDialog(FileDialogMode.Open);
	DOF.FullFileName = FileName;
	DOF.Filter = NStr("vi = 'Tệp khuôn mẫu';
						|ru = 'Файл шаблона';
						|en = 'Template file'; fa = 'Template file';
						|it = 'Файл шаблона';
						|pl = 'Template file';
						|tr = 'Şablon dosyası'") + "(*.xml)|*.xml|" + NStr("vi = 'Tệp khuôn mẫu';
																		|ru = 'Файл шаблона';
																		|en = 'Template file'; fa = 'Template file';
																		|it = 'Файл шаблона';
																		|pl = 'Template file';
																		|tr = 'Şablon dosyası'") + "(*.mxl)|*.mxl"; 
	DOF.Multiselect = False;
	DOF.Title = NStr("vi = 'Hãy chọn tệp khuôn in';
					|ru = 'Выберите файл макета';
					|en = 'Select template file'; fa = 'Select template file';
					|it = 'Selezionare file di layout';
					|pl = 'Wybierz plik szablonu';
					|tr = 'Şablon dosyasını seç'");
	DOF.Show(New CallbackDescription("SelectingFileCompletion", ThisObject, New Structure("DOF", DOF)));
	// APK: 1348-on
	
EndProcedure

&AtClient
Procedure SelectingFileCompletion(SelectedFiles, AdditionalParameters) Export
	
	DOF = AdditionalParameters.DOF;    
	File = New File(SelectedFiles[0]);
	
	If (SelectedFiles <> Undefined) Then
		If File.Extension = ".mxl" Then
			AdditionalParameters.Insert("FileName", SelectedFiles[0]);
			HandlerNotifications = New CallbackDescription(
									"ImportingTemplateFromEndFile",
									ThisObject,
									AdditionalParameters);
			BeginPuttingFiles(HandlerNotifications, Undefined, SelectedFiles[0], False)
		ElsIf File.Extension = ".xml" Then
			FileName = DOF.FullFileName;
			FillAccordingToTemplateData(True);
			TemplateChanged = True;
		EndIf;
	Else
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportingTemplateFromEndFile(PlacedFiles, AdditionalParameters) Export
	
	If PlacedFiles.Count() > 0 Then
		FileAddress = PlacedFiles[0].Location;
		LoadingTemplateFromFileEndingServer(FileAddress);
		If XMLTemplateDetails = "" Then
			MessageText = NStr("vi = 'Không thể chuyển đổi khuôn in.';
								|ru = 'Не удалось конвертировать макет.';
								|en = 'Cannot convert the template.'; fa = 'Cannot convert the template.';
								|it = 'Не удалось конвертировать макет.';
								|pl = 'Cannot convert the template.';
								|tr = 'Şablon dönüştürülemedi.'");
			CommonCELClient.MessageToUser(MessageText);
		Else
			FillAccordingToTemplateData();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure LoadingTemplateFromFileEndingServer(FileAddress)
	
	BinaryData = GetFromTempStorage(FileAddress);
	Directory = TempFilesDir();
	TempFileName = String(New UUID) + ".xml";
	NameOfIntermediateFile = Directory + TempFileName;
	BinaryData.Write(NameOfIntermediateFile);
	TemplateIsTemporary = New SpreadsheetDocument;
	TemplateIsTemporary.Clear();
	TemplateIsTemporary.Read(NameOfIntermediateFile);
	DeleteFiles(NameOfIntermediateFile);
	XMLTemplateDetails = PrintPLLabelsAndPriceTags.ConvertTemplateToXML(TemplateIsTemporary, True);
	
EndProcedure

&AtClient
Procedure ClearingTemplate()
	
	FileName = "";
	Fields.Clear();
	Orientation=0;
	RedrawTemplate();
	
	TemplateChanged = False;
	
EndProcedure

&AtServer
Function GetReferenceTemplate()
	
	Return Catalogs.Peripherals.GetTemplate("LayoutForDeterminingTheCoefficientsOfUnitsOfMeasurement");
	
EndFunction

&AtClient
Procedure UpdateLabelSizes()
	
	Template.Area().BackColor = New Color(128,128,128);
	Template.Area(1, 1, LabelHeight/GridStep, LabelWidth_/GridStep).BackColor = New Color(255,255,255);
	
	For Each CurField In Fields Do
		
		If CurField.Type = "Barcode" Or CurField.Type = "Image" Then
			Template.Area(CurField.Description).BackColor = New Color(235,235,235);
		EndIf;
		
	EndDo;
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	FieldDetails - String - description of the field.
// 	FieldToEdit - Structure - structure with fields:
// 	*Description - String - .
&AtClient
Procedure SaveFieldDescription(FieldDetails, FieldToEdit=Undefined)
	
	If FieldToEdit<>Undefined Then
		TemplateField = Fields.FindRows(New Structure("Description", FieldToEdit.Description))[0];
	Else
		TemplateField	= Fields.Add();
	EndIf;
	
	If FieldDetails.Property("Font") And Not FieldDetails.Font = Undefined Then
		FieldDetails.Font = ChooseFont(FieldDetails.Font);
	EndIf;
	
	TemplateField.Type	= FieldDetails.Type;
	TemplateField.Description	= FieldDetails.Description;
	TemplateField.Value = FieldDetails.Value;
	TemplateField.PopulationType = FieldDetails.PopulationType;
	TemplateField.Value = FieldDetails.Value;
	TemplateField.DefaultValue = FieldDetails.DefaultValue;
	
	If FieldDetails.Type<>"UserData" Then
		
		TemplateField.Top							= FieldDetails.Top;
		TemplateField.Left							= FieldDetails.Left;
		TemplateField.Bottom							= FieldDetails.Bottom;
		TemplateField.Right						= FieldDetails.Right;
		TemplateField.Orientation					= FieldDetails.Orientation;
		
		If FieldDetails.Type = "Text" Then
			TemplateField.Presentation				= FieldDetails.Value;
			TemplateField.FontName					= FieldDetails.Font.Name;
			TemplateField.FontSize					= ?(FieldDetails.Font.Size=-1, 8, FieldDetails.Font.Size);
			TemplateField.Fatty						= FieldDetails.Font.Fatty;
			TemplateField.Italic					= FieldDetails.Font.Italic;
			TemplateField.Underline				= FieldDetails.Font.Underline;
			TemplateField.Strikeout					= FieldDetails.Font.Strikeout;
			TemplateField.LeftFrame					= FieldDetails.LeftFrame;
			TemplateField.TopFrame					= FieldDetails.TopFrame;
			TemplateField.RightFrame					= FieldDetails.RightFrame;
			TemplateField.BottomFrame					= FieldDetails.BottomFrame;
			TemplateField.BorderType						= FieldDetails.BorderType;
			TemplateField.FrameWidth					= FieldDetails.FrameWidth;
			TemplateField.HorizontalPosition		= FieldDetails.HorizontalPosition;
			TemplateField.VerticalPosition			= FieldDetails.VerticalPosition;
			TemplateField.Multiline				= FieldDetails.Multiline;
			TemplateField.Format						= FieldDetails.Format;
			TemplateField.BarcodeType					= Undefined;
			TemplateField.CheckCharacter			= Undefined;
			TemplateField.BarcodeLabel				= Undefined;
			TemplateField.SignatureFontSize			= Undefined;
			TemplateField.Background                          = FieldDetails.Background;
		ElsIf FieldDetails.Type = "Barcode" Then
			FieldPresentation						= StrTemplate(NStr("vi = 'Mã vạch %1';
																		|ru = 'Штрихкод %1';
																		|en = 'Barcode %1'; fa = 'Barcode %1';
																		|it = 'Codice a barre %1';
																		|pl = 'Kod kreskowy: %1';
																		|tr = 'Barkod %1'"), String(FieldDetails.BarcodeType));
			TemplateField.Presentation				= FieldPresentation;
			TemplateField.BarcodeType					= FieldDetails.BarcodeType;
			TemplateField.CheckCharacter			= FieldDetails.CheckCharacter;
			TemplateField.BarcodeLabel				= FieldDetails.BarcodeLabel;
			TemplateField.SignatureFontSize			= FieldDetails.SignatureFontSize;
			TemplateField.FontName					= Undefined;
			TemplateField.FontSize					= Undefined;
			TemplateField.Fatty						= Undefined;
			TemplateField.Italic					= Undefined;
			TemplateField.Underline				= Undefined;
			TemplateField.Strikeout					= Undefined;
			TemplateField.LeftFrame					= Undefined;
			TemplateField.TopFrame					= Undefined;
			TemplateField.RightFrame					= Undefined;
			TemplateField.BottomFrame					= Undefined;
			TemplateField.BorderType						= Undefined;
			TemplateField.FrameWidth					= Undefined;
			TemplateField.HorizontalPosition		= Undefined;
			TemplateField.VerticalPosition			= Undefined;
			TemplateField.Multiline				= Undefined;
		ElsIf FieldDetails.Type = "Image" Then
			TemplateField.Presentation				= NStr("vi = 'Hình ảnh';
															|ru = 'Картинка';
															|en = 'Picture'; fa = 'تصویر';
															|it = 'Immagine';
															|pl = 'Obraz';
															|tr = 'Resim'");
			TemplateField.LeftFrame					= FieldDetails.LeftFrame;
			TemplateField.TopFrame					= FieldDetails.TopFrame;
			TemplateField.RightFrame					= FieldDetails.RightFrame;
			TemplateField.BottomFrame					= FieldDetails.BottomFrame;
			TemplateField.BorderType						= FieldDetails.BorderType;
			TemplateField.FrameWidth					= FieldDetails.FrameWidth;
			TemplateField.FontName					= Undefined;
			TemplateField.FontSize					= Undefined;
			TemplateField.Fatty						= Undefined;
			TemplateField.Italic					= Undefined;
			TemplateField.Underline				= Undefined;
			TemplateField.Strikeout					= Undefined;
			TemplateField.BarcodeType					= Undefined;
			TemplateField.CheckCharacter			= Undefined;
			TemplateField.BarcodeLabel				= Undefined;
			TemplateField.SignatureFontSize			= Undefined;
			TemplateField.HorizontalPosition		= Undefined;
			TemplateField.VerticalPosition			= Undefined;
			TemplateField.Multiline				= Undefined;
			TemplateField.PictureSize				= FieldDetails.PictureSize;
		EndIf;
		
	Else
		TemplateField.Presentation				= FieldDetails.Value;
		TemplateField.Format						= FieldDetails.Format;
		TemplateField.Top							= Undefined;
		TemplateField.Left							= Undefined;
		TemplateField.Bottom							= Undefined;
		TemplateField.Right						= Undefined;
		TemplateField.Orientation					= Undefined;
		TemplateField.FontName					= Undefined;
		TemplateField.FontSize					= Undefined;
		TemplateField.Fatty						= Undefined;
		TemplateField.Italic					= Undefined;
		TemplateField.Underline				= Undefined;
		TemplateField.Strikeout					= Undefined;
		TemplateField.LeftFrame					= Undefined;
		TemplateField.TopFrame					= Undefined;
		TemplateField.RightFrame					= Undefined;
		TemplateField.BottomFrame					= Undefined;
		TemplateField.BorderType						= Undefined;
		TemplateField.FrameWidth					= Undefined;
		TemplateField.HorizontalPosition		= Undefined;
		TemplateField.VerticalPosition			= Undefined;
		TemplateField.Multiline				= Undefined;
		TemplateField.BarcodeType					= Undefined;
		TemplateField.CheckCharacter			= Undefined;
		TemplateField.BarcodeLabel				= Undefined;
		TemplateField.SignatureFontSize			= Undefined;
		
	EndIf;
	
EndProcedure

&AtServer
Function GetXMLDescriptionOfLabel()
	
	Return PeripheralsLabelPrintersServer.SaveXMLFile(LabelWidth_, LabelHeight, Orientation, Fields);
	
EndFunction

&AtClient
Procedure SaveFieldDesign(FieldDetails, OpeningTemplate=False, SpreadsheetDocument=Undefined)
	
	#If WebClient Then
		
		If TypeOf(FieldDetails)<>Type("Structure") Then
			FieldDetails = GetFieldDescription(FieldDetails);
		EndIf;
		
		SaveFieldDesignOnServer(FieldDetails, OpeningTemplate, SpreadsheetDocument);
		
	#Else
	
		If SpreadsheetDocument=Undefined Then
			SpreadsheetDocument = Template;
		EndIf;
		
		Area = SpreadsheetDocument.Area((FieldDetails.Top-1)/GridStep+1, (FieldDetails.Left-1)/GridStep+1, FieldDetails.Bottom/GridStep, FieldDetails.Right/GridStep);
		Area.Merge();
		Area.Name = FieldDetails.Description;
		
		If FieldDetails.Type = "Text" Then
			
			If FieldDetails.PopulationType = "Constant" Then
				Area.FillType=SpreadsheetDocumentAreaFillType.Text;
				Area.Text = FieldDetails.Value;
			Else
				Area.FillType=SpreadsheetDocumentAreaFillType.Parameter;
				Area.Parameter = FieldDetails.Value;
			EndIf;
			
			If FieldDetails.Multiline Then
				Area.TextPlacement=SpreadsheetDocumentTextPlacementType.Wrap;
			Else
				Area.TextPlacement=SpreadsheetDocumentTextPlacementType.Cut;
			EndIf;
			
			Area.TextOrientation = FieldDetails.Orientation;
			
			If FieldDetails.HorizontalPosition = "Left" Then
				Area.HorizontalAlign=HorizontalAlign.Left;
			ElsIf FieldDetails.HorizontalPosition = "Center" Then
				Area.HorizontalAlign=HorizontalAlign.Center;
			ElsIf FieldDetails.HorizontalPosition = "Right" Then
				Area.HorizontalAlign=HorizontalAlign.Right;
			Else
				Area.HorizontalAlign=HorizontalAlign.Left;
			EndIf;
			
			If FieldDetails.VerticalPosition = "Top" Then
				Area.VerticalAlign=VerticalAlign.Top;
			ElsIf FieldDetails.VerticalPosition = "Center" Then
				Area.VerticalAlign=VerticalAlign.Center;
			ElsIf FieldDetails.VerticalPosition = "Bottom" Then
				Area.VerticalAlign=VerticalAlign.Bottom;
			Else
				Area.VerticalAlign=VerticalAlign.Top;
			EndIf;
			
			If GridStep=1 Then
				Multiplier = 1;
			ElsIf GridStep=0.5 Then
				Multiplier = 2;
			ElsIf GridStep = 0.2 Then
				Multiplier = 5;
			Else
				Multiplier = 10;
			EndIf;
			
			If OpeningTemplate Then
				Area.Font = New Font(FieldDetails.FontName,FieldDetails.FontSize * Multiplier, FieldDetails.Fatty, FieldDetails.Italic, FieldDetails.Underline, FieldDetails.Strikeout);
			Else
				Area.Font = New Font(FieldDetails.Font.Name, FieldDetails.Font.Size * Multiplier, FieldDetails.Font.Fatty, FieldDetails.Font.Italic, FieldDetails.Font.Underline, FieldDetails.Font.Strikeout);
			EndIf;
			
			If FieldDetails.Property("Background") Then
				Area.BackColor = FieldDetails.Background;
			EndIf;
			
		ElsIf FieldDetails.Type = "Barcode" Then		
			
			Area.Text = StrTemplate(NStr("vi = 'Mã vạch %1';
										|ru = 'Штрихкод %1';
										|en = 'Barcode %1'; fa = 'Barcode %1';
										|it = 'Codice a barre %1';
										|pl = 'Kod kreskowy: %1';
										|tr = 'Barkod %1'"), String(FieldDetails.BarcodeType));
			Area.TextPlacement=SpreadsheetDocumentTextPlacementType.Wrap;
			
			If GridStep=1 Then
				FontSize = 8;
			ElsIf GridStep=0.5 Then
				FontSize = 16;
			ElsIf GridStep = 0.2 Then
				FontSize = 24;
			Else
				FontSize = 36;
			EndIf;
			
			Area.Font = New Font(, FontSize);
			Area.TextOrientation = FieldDetails.Orientation;
			Area.HorizontalAlign=HorizontalAlign.Center;
			Area.VerticalAlign=VerticalAlign.Center;		
			
		ElsIf FieldDetails.Type = "Image" Then
			Area.Text = NStr("vi = 'Hình ảnh';
							|ru = 'Изображение';
							|en = 'Image'; fa = 'تصویر';
							|it = 'Immagine';
							|pl = 'Image';
							|tr = 'Görsel'");
			Area.TextPlacement=SpreadsheetDocumentTextPlacementType.Wrap;
			
			If GridStep=1 Then
				FontSize = 8;
			ElsIf GridStep=0.5 Then
				FontSize = 16;
			ElsIf GridStep = 0.2 Then
				FontSize = 24;
			Else
				FontSize = 36;
			EndIf;
			
			Area.Font = New Font(, FontSize);
			Area.TextOrientation = FieldDetails.Orientation;
			Area.HorizontalAlign=HorizontalAlign.Center;
			Area.VerticalAlign=VerticalAlign.Center;
		EndIf;
		
		If FieldDetails.Type = "Text" Or FieldDetails.Type = "Image" Then
			
			If FieldDetails.BorderType = "Solid" Then
				LineType = SpreadsheetDocumentCellLineType.Solid;
			ElsIf FieldDetails.BorderType = "Double" Then
				LineType = SpreadsheetDocumentCellLineType.Double;
			ElsIf FieldDetails.BorderType = "Dotted" Then
				LineType = SpreadsheetDocumentCellLineType.Dotted;
			ElsIf FieldDetails.BorderType = "Dashed" Then
				LineType = SpreadsheetDocumentCellLineType.LargeDashed;
			Else
				LineType = SpreadsheetDocumentCellLineType.None;
			EndIf;
			
			Border = New Line(LineType, FieldDetails.FrameWidth);
			
			If FieldDetails.LeftFrame Then
				Area.LeftBorder=Border;
			Else
				Area.LeftBorder=New Line(SpreadsheetDocumentCellLineType.None, 0);
			EndIf;
			
			If FieldDetails.RightFrame Then
				Area.RightBorder=Border;
			Else
				Area.RightBorder=New Line(SpreadsheetDocumentCellLineType.None, 0);
			EndIf;
			
			If FieldDetails.TopFrame Then
				Area.TopBorder=Border;
			Else
				Area.TopBorder=New Line(SpreadsheetDocumentCellLineType.None, 0);
			EndIf;
			
			If FieldDetails.BottomFrame Then
				Area.BottomBorder=Border;
			Else
				Area.BottomBorder=New Line(SpreadsheetDocumentCellLineType.None, 0);
			EndIf;
			
		EndIf;
		
		If FieldDetails.Type = "Barcode" Or FieldDetails.Type = "Image" Then
			Area.BackColor = New Color(235, 235, 235);
		Else
			
			If Not FieldDetails.LeftFrame And Not FieldDetails.TopFrame And Not FieldDetails.RightFrame And Not FieldDetails.BottomFrame Then
				Border = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
				Area.LeftBorder = Border;
				Area.TopBorder = Border;
				Area.RightBorder = Border;
				Area.BottomBorder = Border;
				Area.BorderColor = New Color(235, 235, 235);
			Else
				Area.BorderColor = New Color(0, 0, 0);
			EndIf;
			
		EndIf;
	
	#EndIf
	
EndProcedure

&AtClient
Function SaveXMLFile(SaveToFile_ = False)
	
	If SaveToFile_ Then
		
		Content = GetXMLDescriptionOfLabel();
#If Not MobileClient And Not MobileAppClient Then 
		TextDocument = New TextDocument;
		TextDocument.SetText(Content);
		
		CallbackDescription = New CallbackDescription("SaveXmlFileEnd", ThisObject);
		TextDocument.BeginWriting(CallbackDescription, FileName);
#EndIf
		
	Else
		Return GetXMLDescriptionOfLabel();
	EndIf;
	
EndFunction

&AtClient
Procedure SaveXmlFileEnd(Result, AdditionalParameters) Export
	
	If Result Then
		MessageText = NStr("vi = 'Đã ghi lại tệp %FileName% thành công.';
							|ru = 'Файл %FileName% успешно записан.';
							|en = 'The %FileName% file is saved.'; fa = 'The %FileName% file is saved.';
							|it = 'Файл %FileName% успешно записан.';
							|pl = 'The %FileName% file is saved.';
							|tr = 'Dosya %FileName% başarıyla kaydedildi.'");
		MessageText = StrReplace(MessageText, "%FileName%", FileName);
		CommonCELClient.MessageToUser(MessageText);
	Else
		MessageText = NStr("vi = 'Khi thử ghi lại tệp %FileName% đã xảy ra lỗi.';
							|ru = 'При попытке записи файла %FileName%  произошла ошибка.';
							|en = 'An error occurred when writing the %FileName% file.'; fa = 'An error occurred when writing the %FileName% file.';
							|it = 'Si è verificato un errore durante il tentativo di registrazione del file %FileName%.';
							|pl = 'Podczas próby zapisu pliku %FileName%  wystąpił błąd.';
							|tr = '%FileName% dosyası kaydedilmeye çalışılırken hata oluştu.'");
		MessageText = StrReplace(MessageText, "%FileName%", FileName);
		CommonCELClient.MessageToUser(MessageText);
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearAreaOnServer(Top, Left, Bottom, Right)
	
	Area = Template.Area(Top, Left, Bottom, Right);
	Area.Name = "";
	Area.Picture = Undefined;
	Area.UndoMerge();
	Area.Clear(True, True, True);	
	Area.BackColor = New Color(255,255,255);
	
EndProcedure

&AtServer
Procedure SaveFieldDesignOnServer(FieldDetails, OpeningTemplate=False, SpreadsheetDocument=Undefined)
	
	If SpreadsheetDocument=Undefined Then
		SpreadsheetDocument = Template;
	EndIf;
	
	Area = SpreadsheetDocument.Area((FieldDetails.Top-1)/GridStep+1, (FieldDetails.Left-1)/GridStep+1, FieldDetails.Bottom/GridStep, FieldDetails.Right/GridStep);
	Area.Merge();
	Area.Name = FieldDetails.Description;
	
	If FieldDetails.Type = "Text" Then
		
		If FieldDetails.PopulationType = "Constant" Then
			Area.FillType=SpreadsheetDocumentAreaFillType.Text;
			Area.Text = FieldDetails.Value;
		Else
			Area.FillType=SpreadsheetDocumentAreaFillType.Parameter;
			Area.Parameter = FieldDetails.Value;
		EndIf;
		
		If FieldDetails.Multiline Then
			Area.TextPlacement=SpreadsheetDocumentTextPlacementType.Wrap;
		Else
			Area.TextPlacement=SpreadsheetDocumentTextPlacementType.Cut;
		EndIf;
		
		Area.TextOrientation = FieldDetails.Orientation;
		
		If FieldDetails.HorizontalPosition = "Left" Then
			Area.HorizontalAlign=HorizontalAlign.Left;
		ElsIf FieldDetails.HorizontalPosition = "Center" Then
			Area.HorizontalAlign=HorizontalAlign.Center;
		ElsIf FieldDetails.HorizontalPosition = "Right" Then
			Area.HorizontalAlign=HorizontalAlign.Right;
		Else
			Area.HorizontalAlign=HorizontalAlign.Left;
		EndIf;
		
		If FieldDetails.VerticalPosition = "Top" Then
			Area.VerticalAlign=VerticalAlign.Top;
		ElsIf FieldDetails.VerticalPosition = "Center" Then
			Area.VerticalAlign=VerticalAlign.Center;
		ElsIf FieldDetails.VerticalPosition = "Bottom" Then
			Area.VerticalAlign=VerticalAlign.Bottom;
		Else
			Area.VerticalAlign=VerticalAlign.Top;
		EndIf;
		
		If GridStep=1 Then
			Multiplier = 1;
		ElsIf GridStep=0.5 Then
			Multiplier = 2;
		ElsIf GridStep = 0.2 Then
			Multiplier = 5;
		Else
			Multiplier = 10;
		EndIf;
		
		If OpeningTemplate Then
			Area.Font = New Font(FieldDetails.FontName,FieldDetails.FontSize * Multiplier, FieldDetails.Fatty, FieldDetails.Italic, FieldDetails.Underline, FieldDetails.Strikeout);
		Else
			Area.Font = New Font(FieldDetails.Font.Name, FieldDetails.Font.Size * Multiplier, FieldDetails.Font.Fatty, FieldDetails.Font.Italic, FieldDetails.Font.Underline, FieldDetails.Font.Strikeout);
		EndIf;
		
	ElsIf FieldDetails.Type = "Barcode" Then		
		
		FieldPresentation = StrTemplate(NStr("vi = 'Mã vạch %1';
											|ru = 'Штрихкод %1';
											|en = 'Barcode %1'; fa = 'Barcode %1';
											|it = 'Codice a barre %1';
											|pl = 'Kod kreskowy: %1';
											|tr = 'Barkod %1'"), String(FieldDetails.BarcodeType));
		Area.Text = FieldPresentation;
		Area.TextPlacement=SpreadsheetDocumentTextPlacementType.Wrap;
		
		If GridStep=1 Then
			FontSize = 8;
		ElsIf GridStep=0.5 Then
			FontSize = 16;
		ElsIf GridStep = 0.2 Then
			FontSize = 24;
		Else
			FontSize = 36;
		EndIf;
		
		Area.Font = New Font(, FontSize);
		Area.TextOrientation = FieldDetails.Orientation;
		Area.HorizontalAlign=HorizontalAlign.Center;
		Area.VerticalAlign=VerticalAlign.Center;		
		
	ElsIf FieldDetails.Type = "Image" Then
		Area.Text = NStr("vi = 'Hình ảnh';
						|ru = 'Изображение';
						|en = 'Image'; fa = 'تصویر';
						|it = 'Immagine';
						|pl = 'Image';
						|tr = 'Görsel'");
		Area.TextPlacement=SpreadsheetDocumentTextPlacementType.Wrap;
		
		If GridStep=1 Then
			FontSize = 8;
		ElsIf GridStep=0.5 Then
			FontSize = 16;
		ElsIf GridStep = 0.2 Then
			FontSize = 24;
		Else
			FontSize = 36;
		EndIf;
		
		Area.Font = New Font(, FontSize);
		Area.TextOrientation = FieldDetails.Orientation;
		Area.HorizontalAlign=HorizontalAlign.Center;
		Area.VerticalAlign=VerticalAlign.Center;
	EndIf;
	
	If FieldDetails.Type = "Text" Or FieldDetails.Type = "Image" Then
		
		If FieldDetails.BorderType = "Solid" Then
			LineType = SpreadsheetDocumentCellLineType.Solid;
		ElsIf FieldDetails.BorderType = "Double" Then
			LineType = SpreadsheetDocumentCellLineType.Double;
		ElsIf FieldDetails.BorderType = "Dotted" Then
			LineType = SpreadsheetDocumentCellLineType.Dotted;
		ElsIf FieldDetails.BorderType = "Dashed" Then
			LineType = SpreadsheetDocumentCellLineType.LargeDashed;
		Else
			LineType = SpreadsheetDocumentCellLineType.None;
		EndIf;
		
		Border = New Line(LineType, FieldDetails.FrameWidth);
		
		If FieldDetails.LeftFrame Then
			Area.LeftBorder=Border;
		Else
			Area.LeftBorder=New Line(SpreadsheetDocumentCellLineType.None, 0);
		EndIf;
		
		If FieldDetails.RightFrame Then
			Area.RightBorder=Border;
		Else
			Area.RightBorder=New Line(SpreadsheetDocumentCellLineType.None, 0);
		EndIf;
		
		If FieldDetails.TopFrame Then
			Area.TopBorder=Border;
		Else
			Area.TopBorder=New Line(SpreadsheetDocumentCellLineType.None, 0);
		EndIf;
		
		If FieldDetails.BottomFrame Then
			Area.BottomBorder=Border;
		Else
			Area.BottomBorder=New Line(SpreadsheetDocumentCellLineType.None, 0);
		EndIf;
		
	EndIf;
	
	If FieldDetails.Type = "Barcode" Or FieldDetails.Type = "Image" Then
		Area.BackColor = New Color(235, 235, 235);
	Else
		
		If Not FieldDetails.LeftFrame And Not FieldDetails.TopFrame And Not FieldDetails.RightFrame And Not FieldDetails.BottomFrame Then
			Border = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
			Area.LeftBorder = Border;
			Area.TopBorder = Border;
			Area.RightBorder = Border;
			Area.BottomBorder = Border;
			Area.BorderColor = New Color(235, 235, 235);
		Else
			Area.BorderColor = New Color(0, 0, 0);
		EndIf;
		
	EndIf;
		
EndProcedure

&AtClient
Function GetFieldDescription(FieldDetails)
	
	Result = New Structure;
	
	Result.Insert("Description",			FieldDetails.Description);
	Result.Insert("Type",					FieldDetails.Type);
	Result.Insert("PopulationType",			FieldDetails.PopulationType);
	Result.Insert("DefaultValue",	FieldDetails.DefaultValue);
	Result.Insert("Value",				FieldDetails.Value);
	Result.Insert("Top",					FieldDetails.Top);
	Result.Insert("Left",					FieldDetails.Left);
	Result.Insert("Bottom",					FieldDetails.Bottom);
	Result.Insert("Right",					FieldDetails.Right);
	Result.Insert("Orientation",			FieldDetails.Orientation);
	Result.Insert("FontName",				FieldDetails.FontName);
	Result.Insert("FontSize",			FieldDetails.FontSize);
	Result.Insert("Fatty",				FieldDetails.Fatty);
	Result.Insert("Italic",				FieldDetails.Italic);
	Result.Insert("Underline",			FieldDetails.Underline);
	Result.Insert("Strikeout",			FieldDetails.Strikeout);
	Result.Insert("LeftFrame",			FieldDetails.LeftFrame);
	Result.Insert("TopFrame",			FieldDetails.TopFrame);
	Result.Insert("RightFrame",			FieldDetails.RightFrame);
	Result.Insert("BottomFrame",			FieldDetails.BottomFrame);
	Result.Insert("BorderType",				FieldDetails.BorderType);
	Result.Insert("FrameWidth",			FieldDetails.FrameWidth);
	Result.Insert("BarcodeType",			FieldDetails.BarcodeType);
	Result.Insert("SignatureFontSize",	FieldDetails.SignatureFontSize);
	Result.Insert("BarcodeLabel",		FieldDetails.BarcodeLabel);
	Result.Insert("CheckCharacter",		FieldDetails.CheckCharacter);
	Result.Insert("HorizontalPosition",FieldDetails.HorizontalPosition);
	Result.Insert("VerticalPosition",	FieldDetails.VerticalPosition);
	Result.Insert("Multiline",		FieldDetails.Multiline);
	Result.Insert("Format",				FieldDetails.Format);
	
	Return Result;
	
EndFunction

&AtClient
Procedure PromptUserToContinueEditingEnd(FieldDetails, FieldToEdit)
	
	TransmittedParameters = New Structure;
	TransmittedParameters.Insert("FieldDetails", FieldDetails);
	
	If FieldToEdit<>Undefined Then
		TransmittedParameters.Insert("FieldToEdit", FieldToEdit);
	EndIf;
	
	TransmittedParameters.Insert("ReEditing", True);
	TransmittedParameters.Insert("GridStep", GridStep);
	ShowQueryBox(New CallbackDescription("PromptUserToContinueEditingEndCompletion", ThisObject, TransmittedParameters),
					NStr("vi = 'Không thể ghi lại. Đã sử dụng giá trị hiện tại của mục tin ""Tên trường"". Tiếp tục soạn?';
						|ru = 'Запись невозможна. Текущее значение реквизита ""Имя поля"" уже используется. Продолжить редактирование?';
						|en = 'Cannot save. The current value of the ""Field name"" attribute is already used. Continue editing?'; fa = 'Cannot save. The current value of the ""Field name"" attribute is already used. Continue editing?';
						|it = 'Impossibile registrare. Il valore corrente del requisito ""Nome campo"" è già in utilizzo. Continuare con la modifica?';
						|pl = 'Nie można zapisać. Bieżąca wartość atrybutu ""Nazwa pola"" jest już używana. Kontynuować edycję?';
						|tr = 'Kaydetmek mümkün değil. ""Alan adı"" özniteliğinin mevcut değeri şu anda kullanılıyor. Düzenlemeye devam edilsin mi?'"), QuestionDialogMode.YesNo);
					
EndProcedure

&AtClient
Procedure PromptUserToContinueEditingEndCompletion(Result, TransmittedParameters) Export
	
	If Result=DialogReturnCode.Yes Then
		
		NotificationOnCompletion = New CallbackDescription("StartAddingEditingCompletionField", ThisObject, TransmittedParameters);
		OpenForm("Catalog.TemplatesOfPLLabelsAndPriceTags.Form.LabelEditorFormOfTemplateFieldEditing", New Structure("DCSStorageAddress", DCSStorageAddress),,,,, NotificationOnCompletion);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InterrogateUserAboutDeletingIntersectingFields(TransmittedParameters)
	
	If TransmittedParameters.Property("FieldToEdit") Then
		QueryText = NStr("vi = 'Các biên mới của trường được soạn giao với các trường:%FieldList%Hủy các thay đổi đã nhập?';
						|ru = 'Новые границы редактируемого поля пересекаются с полями:%FieldList%Отменить внесенные изменения?';
						|en = 'New borders of the edited field overlap fields:%FieldList% Cancel the changes?'; fa = 'New borders of the edited field overlap fields:%FieldList% Cancel the changes?';
						|it = 'I nuovi limiti del campo di modifica si sovrappongono ai campi: :%FieldList% Annullare le modifiche apportate?';
						|pl = 'Nowe granice edytowanego pola pokrywają się z polami:%FieldList%Anulować wniesione zmiany?';
						|tr = 'Düzenlenebilir alanların yeni sınırları şu alanlarla çakışıyor: %FieldList% Değişiklikler iptal edilsin mi?'");
	Else
		QueryText = NStr("vi = 'Trường đã tạo giao với các trường hiện tại:%FieldList%Hủy các thay đổi đã nhập?';
						|ru = 'Создаваемое поле пересекается с уже существующими полями:%FieldList%Отменить внесенные изменения?';
						|en = 'Created field overlaps with the existing fields:%FieldList%Cancel the changes made?'; fa = 'Created field overlaps with the existing fields:%FieldList%Cancel the changes made?';
						|it = 'Il campo creato si sovrappone con i campi esistenti: :%FieldList% Annullare le modifiche apportate?';
						|pl = 'Tworzone pole pokrywa się z już istniejącymi polami:%FieldList%Anulować wniesione zmiany?';
						|tr = 'Oluşturulacak alanlar mevcut alanlarla çakışıyor:%FieldList%Değişiklikler iptal edilsin mi?'");
	EndIf;
	
	FieldList = "";
	
	For Each IntersectingField In TransmittedParameters.IntersectingFields Do
		FieldList = FieldList + Chars.LF + IntersectingField.Presentation;
	EndDo;
	
	FieldList = FieldList + "." + Chars.LF;
	
	QueryText = StrReplace(QueryText, "%FieldList%", FieldList);
	
	ShowQueryBox(New CallbackDescription("InterrogateUserAboutDeletingIntersectingFieldsCompletion", ThisObject, TransmittedParameters), QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure InterrogateUserAboutDeletingIntersectingFieldsCompletion(QuestionResult, TransmittedParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		
		TemplateChanged = True;
		IntersectingFields = TransmittedParameters.IntersectingFields;
		
		For Each CurField In IntersectingFields Do
			DeleteFieldDescription(CurField.Description);
			ClearArea((CurField.Top-1)/GridStep+1, (CurField.Left-1)/GridStep+1, CurField.Bottom/GridStep, CurField.Right/GridStep);
		EndDo;
		
		If TransmittedParameters.Property("FieldToEdit") Then
			
			SaveFieldDescription(TransmittedParameters.FieldDetails, TransmittedParameters.FieldToEdit);
			
			If TransmittedParameters.CleanUpOldDesign Then
				ClearArea((TransmittedParameters.FieldToEdit.Top-1)/GridStep+1, (TransmittedParameters.FieldToEdit.Left-1)/GridStep+1, TransmittedParameters.FieldToEdit.Bottom/GridStep, TransmittedParameters.FieldToEdit.Right/GridStep);
			EndIf;
			
			If TransmittedParameters.FieldDetails.Type<>"UserData" Then
				SaveFieldDesign(TransmittedParameters.FieldDetails);
			EndIf;
			
		Else
			
			SaveFieldDescription(TransmittedParameters.FieldDetails);
			
			If TransmittedParameters.FieldDetails.Type<>"UserData" Then
				SaveFieldDesign(TransmittedParameters.FieldDetails);
			EndIf;
			
		EndIf;		
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StartAddingField(SelectedDCSField=Undefined)
	
	Area = Items.Template.CurrentArea;
	
	FieldDetails = New Structure;
	FieldDetails.Insert("Description", String(New UUID));
	FieldDetails.Insert("Top", Area.Top/(1/GridStep)-GridStep);
	FieldDetails.Insert("Left", Area.Left/(1/GridStep)-GridStep);
	FieldDetails.Insert("Bottom", ?(Area.Bottom/(1/GridStep)<=LabelHeight, Area.Bottom/(1/GridStep), LabelHeight));
	FieldDetails.Insert("Right", ?(Area.Right/(1/GridStep)<=LabelWidth_*(1/GridStep), Area.Right/(1/GridStep), LabelWidth_));
	
	If SelectedDCSField<>Undefined Then
		FieldDetails.Insert("Value", SelectedDCSField);
	EndIf;
	
	FieldDetails.Insert("PopulationType", "Parameter");
	
	TransmittedParameters = New Structure;
	TransmittedParameters.Insert("FieldDetails", FieldDetails);
	TransmittedParameters.Insert("GridStep", GridStep);
	
	NotificationOnCompletion = New CallbackDescription("StartAddingEditingCompletionField", ThisObject, TransmittedParameters);
	OpenForm("Catalog.TemplatesOfPLLabelsAndPriceTags.Form.LabelEditorFormOfTemplateFieldEditing", New Structure("DCSStorageAddress", DCSStorageAddress),,,,, NotificationOnCompletion);
	
EndProcedure

// Changes the presence of the boundaries from the specified field layout.
//
// Parameters:
//   FieldName - String - ID of the layout field.
//   BorderIndex - Number - Border index (0-no borders,1-left border,2-upper border,3-right border,4-lower border,5-all borders)
//
&AtClient
Procedure ChangeFieldBoundaries(FieldName, BorderIndex)

	TablePartField = Fields.FindRows(New Structure("Description", FieldName))[0];
	
	If BorderIndex = 0 Then
		
		TablePartField.LeftFrame = False;
		TablePartField.TopFrame = False;
		TablePartField.RightFrame = False;
		TablePartField.BottomFrame = False;
		TablePartField.FrameWidth = 0;
		TablePartField.BorderType = Undefined;
		
	ElsIf BorderIndex = 1 Then
		TablePartField.LeftFrame = Not TablePartField.LeftFrame;
	ElsIf BorderIndex = 2 Then
		TablePartField.TopFrame = Not TablePartField.TopFrame;
	ElsIf BorderIndex = 3 Then
		TablePartField.RightFrame = Not TablePartField.RightFrame;
	ElsIf BorderIndex = 4 Then
		TablePartField.BottomFrame = Not TablePartField.BottomFrame;
	ElsIf BorderIndex = 5 Then
		
		TablePartField.LeftFrame = True;
		TablePartField.TopFrame = True;
		TablePartField.RightFrame = True;
		TablePartField.BottomFrame = True;
		
	EndIf;
	
	If TablePartField.LeftFrame
		Or TablePartField.TopFrame
		Or TablePartField.RightFrame
		Or TablePartField.BottomFrame Then
		
		If TablePartField.FrameWidth=0 Then
			TablePartField.FrameWidth = 1;
		EndIf;
		
		If TablePartField.BorderType="" Then
			TablePartField.BorderType = "Solid";
		EndIf;
		
	EndIf;
	
	FieldDetails = New Structure;
	FieldDetails.Insert("Description",			TablePartField.Description);
	FieldDetails.Insert("Type",					TablePartField.Type);
	FieldDetails.Insert("PopulationType",			TablePartField.PopulationType);
	FieldDetails.Insert("DefaultValue",	TablePartField.DefaultValue);
	FieldDetails.Insert("Value",				TablePartField.Value);
	FieldDetails.Insert("Top",					TablePartField.Top);
	FieldDetails.Insert("Left",					TablePartField.Left);
	FieldDetails.Insert("Bottom",					TablePartField.Bottom);
	FieldDetails.Insert("Right",					TablePartField.Right);
	FieldDetails.Insert("Orientation",				TablePartField.Orientation);
	FieldDetails.Insert("Font",					New Font(TablePartField.FontName, ?(ValueIsFilled(TablePartField.FontSize), TablePartField.FontSize, Undefined), TablePartField.Fatty, TablePartField.Italic, TablePartField.Underline, TablePartField.Strikeout));
	FieldDetails.Insert("LeftFrame",				TablePartField.LeftFrame);
	FieldDetails.Insert("TopFrame",			TablePartField.TopFrame);
	FieldDetails.Insert("RightFrame",			TablePartField.RightFrame);
	FieldDetails.Insert("BottomFrame",				TablePartField.BottomFrame);
	FieldDetails.Insert("BorderType",				TablePartField.BorderType);
	FieldDetails.Insert("FrameWidth",			TablePartField.FrameWidth);
	FieldDetails.Insert("BarcodeType",			TablePartField.BarcodeType);
	FieldDetails.Insert("SignatureFontSize",	TablePartField.SignatureFontSize);
	FieldDetails.Insert("BarcodeLabel",		TablePartField.BarcodeLabel);
	FieldDetails.Insert("CheckCharacter",		TablePartField.CheckCharacter);
	FieldDetails.Insert("HorizontalPosition",	TablePartField.HorizontalPosition);
	FieldDetails.Insert("VerticalPosition",	TablePartField.VerticalPosition);
	FieldDetails.Insert("Multiline",		TablePartField.Multiline);
	FieldDetails.Insert("Format",					TablePartField.Format);
	
	SaveFieldDesign(FieldDetails);
	
	TemplateChanged = True;
	
EndProcedure

// Changes the coordinate of the specified border of the specified layout field.
//
// Parameters:
//   TablePartField - String - The field of the tabular part.
//   BorderIndex - Number - Border index (0-no borders,1-left border,2-upper border,3-right border,4-lower border,5-all borders)
//   MagnitudeOfChange - Number - 
//  
&AtClient
Function AllowBorderChanges(TablePartField, BorderIndex, MagnitudeOfChange)
	
	// We determine the received coordinates of the fields
	Left = TablePartField.Left-1 + ?(BorderIndex = 1, MagnitudeOfChange, 0);
	Top = TablePartField.Top-1 + ?(BorderIndex = 2, MagnitudeOfChange, 0);
	Right = TablePartField.Right + ?(BorderIndex = 3, MagnitudeOfChange, 0);
	Bottom = TablePartField.Bottom + ?(BorderIndex = 4, MagnitudeOfChange, 0);
	
	// Checking for going beyond the boundaries of the layout
	If Left>LabelWidth_ Or Left<0 Then
		Return False;
	EndIf;
	
	If Right>LabelWidth_ Or Right<0 Then
		Return False;
	EndIf;
	
	If Left>Right Then
		Return False;
	EndIf;
	
	If Top>LabelHeight Or Top<0 Then
		Return False;
	EndIf;
	
	If Bottom>LabelHeight Or Bottom<0 Then
		Return False;
	EndIf;
	
	If Top>Bottom Then
		Return False;
	EndIf;
		
	// Checking the intersection with its own borders
	If TablePartField.Left-GridStep + ?(BorderIndex = 1, MagnitudeOfChange, 0)>TablePartField.Right + ?(BorderIndex = 3, MagnitudeOfChange, 0) Or TablePartField.Top-GridStep + ?(BorderIndex = 2, MagnitudeOfChange, 0)>TablePartField.Bottom + ?(BorderIndex = 4, MagnitudeOfChange, 0) Then
		Return False;
	EndIf;
	
	// Check the intersection with other fields.
	For Each CurField In Fields Do
		
		If CurField <> TablePartField Then
			
			HorizontalIntersection = False;
			
			If ((CurField.Left-GridStep<=Left And Left<=CurField.Right-GridStep) Or (CurField.Left-GridStep<=Right And Right<=CurField.Right-GridStep))
				Or ((Left<=CurField.Left-GridStep And CurField.Left-GridStep<=Right) Or (Left<=CurField.Right-GridStep And CurField.Right-GridStep<=Right)) Then
				HorizontalIntersection = True;
			EndIf;
				
			If HorizontalIntersection Then
				
				VerticalIntersection = False;
				
				If ((CurField.Top-GridStep<=Top And Top<=CurField.Bottom-GridStep) Or (CurField.Top-GridStep<=Bottom And Bottom<=CurField.Bottom-GridStep))
					Or ((Top<=CurField.Top-GridStep And CurField.Top-GridStep<=Bottom) Or (Top<=CurField.Bottom-GridStep And CurField.Bottom<=Bottom-GridStep)) Then
					VerticalIntersection = True;
				EndIf;
			
				If VerticalIntersection Then
					
					Return False;
					
				EndIf;
				
			EndIf;
			
		EndIf;
			
	EndDo;
	
	Return True;
	
EndFunction

// Changes the coordinate of the specified border of the specified layout field.
//
// Parameters:
//   FieldName - String - field name.
//   BorderIndex - Number - Border index (0-no borders,1-left border,2-upper border,3-right border,4-lower border,5-all borders)
//   MagnitudeOfChange - Number - 
//
&AtClient
Procedure ChangeBorderCoordinate(FieldName, BorderIndex, MagnitudeOfChange)
	
	TablePartField = Fields.FindRows(New Structure("Description", FieldName))[0];
	
	If AllowBorderChanges(TablePartField, BorderIndex, MagnitudeOfChange) Then
		
		ClearArea((TablePartField.Top-1)/GridStep+1, (TablePartField.Left-1)/GridStep+1, TablePartField.Bottom/GridStep, TablePartField.Right/GridStep);
		
		If BorderIndex = 1 Then		
			TablePartField.Left = TablePartField.Left + MagnitudeOfChange;
		ElsIf BorderIndex = 2 Then		
			TablePartField.Top = TablePartField.Top + MagnitudeOfChange;
		ElsIf BorderIndex = 3 Then		
			TablePartField.Right = TablePartField.Right + MagnitudeOfChange;
		ElsIf BorderIndex = 4 Then		
			TablePartField.Bottom = TablePartField.Bottom + MagnitudeOfChange;
		EndIf;
		
		FieldDetails = New Structure;
		FieldDetails.Insert("Description",			TablePartField.Description);
		FieldDetails.Insert("Type",					TablePartField.Type);
		FieldDetails.Insert("PopulationType",			TablePartField.PopulationType);
		FieldDetails.Insert("DefaultValue",	TablePartField.DefaultValue);
		FieldDetails.Insert("Value",				TablePartField.Value);
		FieldDetails.Insert("Top",					TablePartField.Top);
		FieldDetails.Insert("Left",					TablePartField.Left);
		FieldDetails.Insert("Bottom",					TablePartField.Bottom);
		FieldDetails.Insert("Right",					TablePartField.Right);
		FieldDetails.Insert("Orientation",				TablePartField.Orientation);
		FieldDetails.Insert("Font",					New Font(TablePartField.FontName, ?(ValueIsFilled(TablePartField.FontSize), TablePartField.FontSize, Undefined), TablePartField.Fatty, TablePartField.Italic, TablePartField.Underline, TablePartField.Strikeout));
		FieldDetails.Insert("LeftFrame",				TablePartField.LeftFrame);
		FieldDetails.Insert("TopFrame",			TablePartField.TopFrame);
		FieldDetails.Insert("RightFrame",			TablePartField.RightFrame);
		FieldDetails.Insert("BottomFrame",				TablePartField.BottomFrame);
		FieldDetails.Insert("BorderType",				?(ValueIsFilled(TablePartField.BorderType), TablePartField.BorderType, "Solid"));
		FieldDetails.Insert("FrameWidth",			?(ValueIsFilled(TablePartField.FrameWidth), TablePartField.FrameWidth, 1));
		FieldDetails.Insert("BarcodeType",			TablePartField.BarcodeType);
		FieldDetails.Insert("SignatureFontSize",	TablePartField.SignatureFontSize);
		FieldDetails.Insert("BarcodeLabel",		TablePartField.BarcodeLabel);
		FieldDetails.Insert("CheckCharacter",		TablePartField.CheckCharacter);
		FieldDetails.Insert("HorizontalPosition",	TablePartField.HorizontalPosition);
		FieldDetails.Insert("VerticalPosition",	TablePartField.VerticalPosition);
		FieldDetails.Insert("Multiline",		TablePartField.Multiline);
		FieldDetails.Insert("Format",					TablePartField.Format);
		
		SaveFieldDesign(FieldDetails);
		
		Items.Template.CurrentArea = Template.Area(FieldName);
		
		SetCaptionsForBorders(FieldDetails);
		
		TemplateChanged = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetFormattingButtonMarkings()
	
	FieldName = Items.Template.CurrentArea.Name;
	FoundFields = Fields.FindRows(New Structure("Description", FieldName));
	
	If FoundFields.Count()>0 Then
		
		Field = FoundFields[0];
		
		Items.Bold.Check		= Field.Fatty;
		Items.Italics.Check			= Field.Italic;
		Items.Underscore.Check	= Field.Underline;
		
		Items.AlignLeft.Check			= Field.HorizontalPosition="Left";
		Items.AlignCenter.Check				= Field.HorizontalPosition="Center";
		Items.AlignRight.Check			= Field.HorizontalPosition="Right";
		Items.TopAlign.Check			= Field.VerticalPosition="Top";
		Items.SetVerticalAlignmentToCenter.Check	= Field.VerticalPosition="Center";
		Items.BottomAlign.Check			= Field.VerticalPosition="Bottom";
		
		Items.LeftBorder.Check	= Field.LeftFrame;
		Items.RightBorder.Check	= Field.RightFrame;
		Items.TopBorder.Check	= Field.TopFrame;
		Items.BottomBorder.Check	= Field.BottomFrame;
		
	Else
		
		Items.Bold.Check		= False;
		Items.Italics.Check			= False;
		Items.Underscore.Check	= False;
		
		Items.LeftBorder.Check	= False;
		Items.RightBorder.Check	= False;
		Items.TopBorder.Check	= False;
		Items.BottomBorder.Check	= False;
		
		Items.AlignLeft.Check			= False;
		Items.AlignCenter.Check				= False;
		Items.AlignRight.Check			= False;
		Items.TopAlign.Check			= False;
		Items.SetVerticalAlignmentToCenter.Check	= False;
		Items.BottomAlign.Check			= False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetAvailabilityAndVisibilityOfFieldChangeElements(Var_Enabled, FieldType=Undefined)
	
	Items.ChangeTheField.Enabled = Var_Enabled;
	Items.RemoveField.Enabled = Var_Enabled;
	Items.ContextMenuToChangeTheField.Enabled = Var_Enabled;
	Items.ContextMenuToDeleteAField.Enabled = Var_Enabled;
	
	FieldHasVisualPresentation = False;
	FieldHasFrames = False;
	TextField = False;
		
	If ValueIsFilled(FieldType) Then
		
		If FieldType <> "UserData" Then
			
			FieldHasVisualPresentation = True;
			
			If FieldType = "Text" Then
				TextField = True;
			EndIf;
			
			If FieldType <> "Barcode" Then
				FieldHasFrames = True;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	AvailabilityOfFrameChanges	= Var_Enabled And FieldHasVisualPresentation And FieldHasFrames;
	
	Items.LeftBorder.Enabled					= AvailabilityOfFrameChanges;
	Items.MoveTheLeftBorderToTheLeft.Enabled		= AvailabilityOfFrameChanges;
	Items.MoveTheLeftBorderToTheRight.Enabled		= AvailabilityOfFrameChanges;
	Items.DecorationLeft.Visible					= AvailabilityOfFrameChanges;
	
	Items.RightBorder.Enabled					= AvailabilityOfFrameChanges;
	Items.MoveTheRightBorderToTheLeft.Enabled		= AvailabilityOfFrameChanges;
	Items.MoveTheRightBorderToTheRight.Enabled	= AvailabilityOfFrameChanges;
	Items.DecorationRight.Visible					= AvailabilityOfFrameChanges;
	
	Items.TopBorder.Enabled					= AvailabilityOfFrameChanges;
	Items.IncreaseUpperBound.Enabled			= AvailabilityOfFrameChanges;
	Items.DecreaseUpperBound.Enabled			= AvailabilityOfFrameChanges;
	Items.DecorationTop.Visible					= AvailabilityOfFrameChanges;
	
	Items.BottomBorder.Enabled					= AvailabilityOfFrameChanges;
	Items.IncreaseLowerBound.Enabled			= AvailabilityOfFrameChanges;
	Items.DecreaseLowerBound.Enabled			= AvailabilityOfFrameChanges;
	Items.DecorationBottom.Visible						= AvailabilityOfFrameChanges;
	
	Items.OutsideBorder.Enabled					= AvailabilityOfFrameChanges;
	Items.RemoveLimits.Enabled					= AvailabilityOfFrameChanges;
	
	AvailabilityOfDesignChanges = Var_Enabled And TextField;
	
	Items.SetVerticalAlignmentToCenter.Enabled	= AvailabilityOfDesignChanges;
	Items.TopAlign.Enabled			= AvailabilityOfDesignChanges;
	Items.AlignLeft.Enabled			= AvailabilityOfDesignChanges;
	Items.BottomAlign.Enabled			= AvailabilityOfDesignChanges;
	Items.AlignRight.Enabled			= AvailabilityOfDesignChanges;
	Items.AlignCenter.Enabled				= AvailabilityOfDesignChanges;
	
	Items.Bold.Enabled							= AvailabilityOfDesignChanges;
	Items.Italics.Enabled								= AvailabilityOfDesignChanges;
	Items.Underscore.Enabled						= AvailabilityOfDesignChanges;
	
	SetFormattingButtonMarkings();
	
EndProcedure

&AtClient
Procedure SetCaptionsForBorders(SD)
	
	FS = "NFD=1; NZ=0,0; NG=0";
	Items.DecorationLeft.Title = Format(SD.Left-1, FS);
	Items.DecorationRight.Title = Format(SD.Right, FS);
	Items.DecorationTop.Title = Format(SD.Top-1, FS);
	Items.DecorationBottom.Title = Format(SD.Bottom, FS);
	
EndProcedure

&AtClient
Procedure SetVerticalPositionOfText(SD, Value)
	
	
	ClearArea((SD.Top-1)/GridStep+1, (SD.Left-1)/GridStep+1, SD.Bottom/GridStep, SD.Right/GridStep);
		
	SD.VerticalPosition = Value;
	
	FieldDetails = New Structure;
	FieldDetails.Insert("Description",			SD.Description);
	FieldDetails.Insert("Type",					SD.Type);
	FieldDetails.Insert("PopulationType",			SD.PopulationType);
	FieldDetails.Insert("DefaultValue",	SD.DefaultValue);
	FieldDetails.Insert("Value",				SD.Value);
	FieldDetails.Insert("Top",					SD.Top);
	FieldDetails.Insert("Left",					SD.Left);
	FieldDetails.Insert("Bottom",					SD.Bottom);
	FieldDetails.Insert("Right",					SD.Right);
	FieldDetails.Insert("Orientation",				SD.Orientation);
	FieldDetails.Insert("Font",					New Font(SD.FontName, ?(ValueIsFilled(SD.FontSize), SD.FontSize, Undefined), SD.Fatty, SD.Italic, SD.Underline, SD.Strikeout));
	FieldDetails.Insert("LeftFrame",				SD.LeftFrame);
	FieldDetails.Insert("TopFrame",			SD.TopFrame);
	FieldDetails.Insert("RightFrame",			SD.RightFrame);
	FieldDetails.Insert("BottomFrame",				SD.BottomFrame);
	FieldDetails.Insert("BorderType",				?(ValueIsFilled(SD.BorderType), SD.BorderType, "Solid"));
	FieldDetails.Insert("FrameWidth",			?(ValueIsFilled(SD.FrameWidth), SD.FrameWidth, 1));
	FieldDetails.Insert("BarcodeType",			SD.BarcodeType);
	FieldDetails.Insert("SignatureFontSize",	SD.SignatureFontSize);
	FieldDetails.Insert("BarcodeLabel",		SD.BarcodeLabel);
	FieldDetails.Insert("CheckCharacter",		SD.CheckCharacter);
	FieldDetails.Insert("HorizontalPosition",	SD.HorizontalPosition);
	FieldDetails.Insert("VerticalPosition",	SD.VerticalPosition);
	FieldDetails.Insert("Multiline",		SD.Multiline);
	FieldDetails.Insert("Format",					SD.Format);
	
	SaveFieldDesign(FieldDetails);
	
	TemplateChanged = True;
	
EndProcedure

&AtClient
Procedure SetHorizontalPositionOfText(SD, Value)
	
	
	ClearArea((SD.Top-1)/GridStep+1, (SD.Left-1)/GridStep+1, SD.Bottom/GridStep, SD.Right/GridStep);
		
	SD.HorizontalPosition = Value;
	
	FieldDetails = New Structure;
	FieldDetails.Insert("Description",			SD.Description);
	FieldDetails.Insert("Type",					SD.Type);
	FieldDetails.Insert("PopulationType",			SD.PopulationType);
	FieldDetails.Insert("DefaultValue",	SD.DefaultValue);
	FieldDetails.Insert("Value",				SD.Value);
	FieldDetails.Insert("Top",					SD.Top);
	FieldDetails.Insert("Left",					SD.Left);
	FieldDetails.Insert("Bottom",					SD.Bottom);
	FieldDetails.Insert("Right",					SD.Right);
	FieldDetails.Insert("Orientation",				SD.Orientation);
	FieldDetails.Insert("Font",					New Font(SD.FontName, ?(ValueIsFilled(SD.FontSize), SD.FontSize, Undefined), SD.Fatty, SD.Italic, SD.Underline, SD.Strikeout));
	FieldDetails.Insert("LeftFrame",				SD.LeftFrame);
	FieldDetails.Insert("TopFrame",			SD.TopFrame);
	FieldDetails.Insert("RightFrame",			SD.RightFrame);
	FieldDetails.Insert("BottomFrame",				SD.BottomFrame);
	FieldDetails.Insert("BorderType",				?(ValueIsFilled(SD.BorderType), SD.BorderType, "Solid"));
	FieldDetails.Insert("FrameWidth",			?(ValueIsFilled(SD.FrameWidth), SD.FrameWidth, 1));
	FieldDetails.Insert("BarcodeType",			SD.BarcodeType);
	FieldDetails.Insert("SignatureFontSize",	SD.SignatureFontSize);
	FieldDetails.Insert("BarcodeLabel",		SD.BarcodeLabel);
	FieldDetails.Insert("CheckCharacter",		SD.CheckCharacter);
	FieldDetails.Insert("HorizontalPosition",	SD.HorizontalPosition);
	FieldDetails.Insert("VerticalPosition",	SD.VerticalPosition);
	FieldDetails.Insert("Multiline",		SD.Multiline);
	FieldDetails.Insert("Format",					SD.Format);
	
	SaveFieldDesign(FieldDetails);
	
	TemplateChanged = True;
	
EndProcedure

&AtClient
Procedure ChangeFont(SD, PropertyIndex)
	
	ClearArea((SD.Top-1)/GridStep+1, (SD.Left+1)/GridStep+1, SD.Bottom/GridStep, SD.Right/GridStep);
	
	If PropertyIndex=1 Then
		SD.Fatty = Not SD.Fatty;
	ElsIf PropertyIndex=2 Then
		SD.Italic = Not SD.Italic;
	ElsIf PropertyIndex=3 Then
		SD.Underline = Not SD.Underline;
	EndIf;
	
	FieldDetails = New Structure;
	FieldDetails.Insert("Description",			SD.Description);
	FieldDetails.Insert("Type",					SD.Type);
	FieldDetails.Insert("PopulationType",			SD.PopulationType);
	FieldDetails.Insert("DefaultValue",	SD.DefaultValue);
	FieldDetails.Insert("Value",				SD.Value);
	FieldDetails.Insert("Top",					SD.Top);
	FieldDetails.Insert("Left",					SD.Left);
	FieldDetails.Insert("Bottom",					SD.Bottom);
	FieldDetails.Insert("Right",					SD.Right);
	FieldDetails.Insert("Orientation",				SD.Orientation);
	FieldDetails.Insert("Font",					New Font(SD.FontName, ?(ValueIsFilled(SD.FontSize), SD.FontSize, Undefined), SD.Fatty, SD.Italic, SD.Underline, SD.Strikeout));
	FieldDetails.Insert("LeftFrame",				SD.LeftFrame);
	FieldDetails.Insert("TopFrame",			SD.TopFrame);
	FieldDetails.Insert("RightFrame",			SD.RightFrame);
	FieldDetails.Insert("BottomFrame",				SD.BottomFrame);
	FieldDetails.Insert("BorderType",				?(ValueIsFilled(SD.BorderType), SD.BorderType, "Solid"));
	FieldDetails.Insert("FrameWidth",			?(ValueIsFilled(SD.FrameWidth), SD.FrameWidth, 1));
	FieldDetails.Insert("BarcodeType",			SD.BarcodeType);
	FieldDetails.Insert("SignatureFontSize",	SD.SignatureFontSize);
	FieldDetails.Insert("BarcodeLabel",		SD.BarcodeLabel);
	FieldDetails.Insert("CheckCharacter",		SD.CheckCharacter);
	FieldDetails.Insert("HorizontalPosition",	SD.HorizontalPosition);
	FieldDetails.Insert("VerticalPosition",	SD.VerticalPosition);
	FieldDetails.Insert("Multiline",		SD.Multiline);
	FieldDetails.Insert("Format",					SD.Format);
	
	SaveFieldDesign(FieldDetails);
	
	TemplateChanged = True;
	
EndProcedure

&AtClient
Function GetCoordinateProjection(Coordinate, NewGridStep)
	
	Quotient = Coordinate/NewGridStep;
	
	If Int(Quotient) = Quotient Then
		Return Coordinate;
	Else
		
		OffsetDownwards = Int(Quotient)*NewGridStep;
		OffsetUpwards = (Int(Quotient) + 1)*NewGridStep;
		
		If OffsetUpwards-Coordinate<=Coordinate-OffsetDownwards Then
			Return OffsetUpwards;
		Else
			Return OffsetDownwards;
		EndIf;
		
	EndIf;
	
EndFunction

&AtClient
// Returns an array of fields
//
// Parameters:
//  Newshagset - Number
//
// Returns:
//   Array of Structure:
//    * Id - Number
//  
Function GetFieldProjections(NewGridStep)
	
	FieldProjections = New Array;
	
	For Each CurField In Fields Do
		
		NewField = New Structure;
		
		NewField.Insert("Description",				CurField.Description);
		NewField.Insert("Type",						CurField.Type);
		NewField.Insert("Value",					CurField.Value);
		NewField.Insert("Orientation",				CurField.Orientation);
		NewField.Insert("FontName",					CurField.FontName);
		NewField.Insert("FontSize",				CurField.FontSize);
		NewField.Insert("Fatty",					CurField.Fatty);
		NewField.Insert("Italic",					CurField.Italic);
		NewField.Insert("Underline",				CurField.Underline);
		NewField.Insert("Strikeout",				CurField.Strikeout);
		NewField.Insert("LeftFrame",				CurField.LeftFrame);
		NewField.Insert("TopFrame",				CurField.TopFrame);
		NewField.Insert("RightFrame",				CurField.RightFrame);
		NewField.Insert("BottomFrame",				CurField.BottomFrame);
		NewField.Insert("BorderType",					CurField.BorderType);
		NewField.Insert("FrameWidth",				CurField.FrameWidth);
		NewField.Insert("BarcodeType",				CurField.BarcodeType);
		NewField.Insert("BarcodeLabel",			CurField.BarcodeLabel);
		NewField.Insert("SignatureFontSize",		CurField.SignatureFontSize);
		NewField.Insert("HorizontalPosition",	CurField.HorizontalPosition);
		NewField.Insert("VerticalPosition",		CurField.VerticalPosition);
		NewField.Insert("Multiline",			CurField.Multiline);
		NewField.Insert("CheckCharacter",			CurField.CheckCharacter);
		NewField.Insert("PopulationType",				CurField.PopulationType);
		NewField.Insert("DefaultValue",		CurField.DefaultValue);
		NewField.Insert("Presentation",				CurField.Presentation);
		NewField.Insert("Format",					CurField.Format);
		NewField.Insert("Left",						GetCoordinateProjection(CurField.Left-1, NewGridStep)+1);
		NewField.Insert("Top",						GetCoordinateProjection(CurField.Top-1, NewGridStep)+1);
		NewField.Insert("Bottom",						GetCoordinateProjection(CurField.Bottom, NewGridStep));
		NewField.Insert("Right",						GetCoordinateProjection(CurField.Right, NewGridStep));
		NewField.Insert("Id",				CurField.GetID());
		
		FieldProjections.Add(NewField);
		
	EndDo;
	
	Return FieldProjections;
	
EndFunction

&AtClient
Procedure ProcessUserSDecision(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult=DialogReturnCode.Yes Then
		
		For Each CurField In AdditionalParameters.FieldsToDelete__ Do
			Fields.Delete(Fields.FindByID(CurField));
		EndDo;
		
		ApplyNewCoordinates(AdditionalParameters.FieldProjections, AdditionalParameters.NewGridStep);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RedrawTemplate(FieldArray=Undefined)
	
	AddToListOfFields = True;
	
	If FieldArray=Undefined Then
		FieldArray = Fields;
		AddToListOfFields = False;
	EndIf;
	
	TabDoc = New SpreadsheetDocument;
	
	TabDoc.Area().AutoRowHeight = False;	
	TabDoc.Area().RowHeight = OneMillimeterOfHeight;
	TabDoc.Area().ColumnWidth = OneMillimeterWide;
	
	TabDoc.Area().BackColor = New Color(128,128,128);
	TabDoc.Area(1, 1, LabelHeight/GridStep, LabelWidth_/GridStep).BackColor = New Color(255,255,255);
	
	For Each CurField In FieldArray Do
		
		If AddToListOfFields Then
			NewField = Fields.Add();
			FillPropertyValues(NewField, CurField); 
			NewField.Background = New Color(255,255,255);
		EndIf;
		
		If CurField.Type<>"UserData" Then			
			SaveFieldDesign(CurField, True, TabDoc);
		EndIf;
		
	EndDo;
	
	Template = TabDoc;
	
EndProcedure

&AtClient
Procedure ApplyNewCoordinates(FieldProjections, NewGridStep)
	
	For Each CurField In Fields Do
		If CurField.Type<>"UserData" Then
			ClearArea((CurField.Top-1)/GridStep+1, (CurField.Left-1)/GridStep+1, CurField.Bottom/GridStep, CurField.Right/GridStep);
		EndIf;
	EndDo;
	
	Fields.Clear();
	
	GridStep = NewGridStep;
	
	LabelHeight = GetCoordinateProjection(LabelHeight, NewGridStep);
	LabelWidth_ = GetCoordinateProjection(LabelWidth_, NewGridStep);
	
	RedrawTemplate(FieldProjections);
	
	TemplateChanged = True;
	
EndProcedure

&AtClient
Procedure LoadFromFileCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult=DialogReturnCode.Yes Then
		SelectingFile();
	EndIf;
    
EndProcedure

&AtClient
Procedure SaveToFileCompletion(SelectedFiles, AdditionalParameters) Export
	
	DOF = AdditionalParameters.DOF;
	
	If (SelectedFiles <> Undefined) Then
		FileName = DOF.FullFileName;
		SaveXMLFile(True);
	Else
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearTemplateCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult=DialogReturnCode.Yes Then
		ClearingTemplate();
		TemplateChanged = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult=DialogReturnCode.Yes Then
		CloseForm = True;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure EditAdditionalDataCompletion(Result, TransmittedParameters) Export
	
	If Result = DialogReturnCode.OK Then
		
		For Each CurField In Fields Do
			
			If CurField.Type = "UserData" Then
				
				StringSearchStructure = TheStructureOfTheSearch();
				StringSearchStructure.Description = Items.Template.CurrentArea.Name;
				FoundRows = Fields.FindRows(StringSearchStructure);
				
				If FoundRows.Count()>0 Then
					
					SD = FoundRows[0]; //See TheStructureOfTheSearch
					DeleteFieldDescription(SD.Description);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		For Each CurField In TransmittedParameters.Fields Do
			
			PP = New Structure;
			PP.Insert("FieldDetails", CurField);
			
			StartAddingEditingCompletionField(DialogReturnCode.OK, PP);
			
		EndDo;
		
		TemplateChanged = True;
		
	EndIf;
	
EndProcedure

&AtClient
Function TheStructureOfTheSearch()

	TheStructureOfTheSearch = New Structure();
	TheStructureOfTheSearch.Insert("Description");
	
	Return TheStructureOfTheSearch;
	
EndFunction 

&AtClient
Procedure ProcessingOpeningOfDCSSettings(Result, OperationParametersList) Export
	
	PrintPLLabelsAndPriceTagsClientOverridable.ProcessingOpeningOfDCSSettings(Result, OperationParametersList);
	
EndProcedure

&AtClient
Function FontStyleOnClient(Font)
	#If Not WebClient Then
		XMLWriter = New XMLWriter;
		XMLWriter.SetString();
		XDTOSerializer.WriteXML(XMLWriter, Font, XMLTypeAssignment.Explicit);

		StringFont = XMLWriter.Close();
		// Define a style
		StyleName = "";
		SearchPosition = StrFind(StringFont, "ref=""");
		If SearchPosition > 0 Then
			StyleName = Mid(StringFont, SearchPosition + 5);
			SearchPosition = StrFind(StyleName, """");
			StyleName = Left(StyleName, SearchPosition - 1);
		EndIf;

		Return StyleName;
	#EndIf
EndFunction

&AtServerNoContext
Function FontStyleOnServer(Font)
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XDTOSerializer.WriteXML(XMLWriter, Font, XMLTypeAssignment.Explicit);

	StringFont = XMLWriter.Close();
	// Define a style
	StyleName = "";
	SearchPosition = StrFind(StringFont, "ref=""");
	If SearchPosition > 0 Then
		StyleName = Mid(StringFont, SearchPosition + 5);
		SearchPosition = StrFind(StyleName, """");
		StyleName = Left(StyleName, SearchPosition - 1);
	EndIf;

	Return StyleName;
EndFunction

&AtServerNoContext
Function FontOfStyleElementOnServer(FontStyle_)
	Return Metadata.StyleItems[Mid(FontStyle_,7)].Value;
EndFunction

// Choose a similar font for windows fonts and style fonts
// Parameters:
//  Font - Font
&AtClient
Function ChooseFont(Font)
	
	If Font.Type = FontType.Absolute Then
		Return Font;
	EndIf;
	
	FontName = "Arial";
	FontSize = 8;
	
	#If WebClient Then
		
		FontStyle_ = FontStyleOnServer(Font);
		
	#Else
		
		FontStyle_ = FontStyleOnClient(Font);
		
	#EndIf
	
	If Font.Type = FontType.WindowsFont Then
		
		If FontStyle_ = "sys:DefaultGUIFont" Then
			FontName = "MS Sans Serif";
		ElsIf FontStyle_ = "sys:OEMFixedFont" Then
			FontName = "Courier New";
		ElsIf FontStyle_ = "sys:ANSIFixedFont" Then
			FontName = "Courier New";
		ElsIf FontStyle_ = "sys:ANSIVariableFont" Then
			FontName = "MS Sans Serif";
		ElsIf FontStyle_ = "sys:SystemFont" Then
			FontName = "System";
		EndIf;
		
	ElsIf Font.Type = FontType.StyleItem Then
		
		If FontStyle_ = "style:TextFont" Then
			FontName = "Arial";
		ElsIf FontStyle_ = "style:SmallTextFont" Then
			FontName = "Arial";
			FontSize = 8;
		ElsIf FontStyle_ = "style:NormalTextFont" Then
			FontName = "Arial";
			FontSize =10;
		ElsIf FontStyle_ = "style:LargeTextFont" Then
			FontName = "Arial";
			FontSize =14;
		ElsIf FontStyle_ = "style:ExtraLargeTextFont" Then
			FontName = "Arial";
			FontSize =18;
		Else
			Return ChooseFont(FontOfStyleElementOnServer(FontStyle_));
		EndIf;
		
	EndIf;
	
	If Font.Size <> -1 Then
		FontSize = Font.Size;
	EndIf;
	Return New Font(FontName, FontSize, 
		Font.Bold, Font.Italic, Font.Underline, Font.Strikeout, Font.Scale);
	
EndFunction

&AtClient
Procedure StartDownloadingFromFile(Result, AdditionalParameters) Export
	
	If Fields.Count()>0 Then
		ShowQueryBox(New CallbackDescription("LoadFromFileCompletion", ThisObject), NStr("vi = 'Kết nhập khuôn in nhãn tem từ tệp?';
																						|ru = 'Загрузить макет этикетки из файла?';
																						|en = 'Import the label template from file?'; fa = 'Import the label template from file?';
																						|it = 'Загрузить макет этикетки из файла?';
																						|pl = 'Pobrać szablon etykiety z pliku?';
																						|tr = 'Dosyadan etiket şablonu yüklensin mi?'"), QuestionDialogMode.YesNo);
	Else
		SelectingFile();
	EndIf;
	
EndProcedure 

&AtClient
Procedure StartSavingToFile(Result, AdditionalParameters) Export
	
	// APK: 1348-off the filesystem Client module from BSP is not used
	DOF = New FileDialog(FileDialogMode.Save);
	DOF.FullFileName = FileName;
	DOF.Filter = NStr("vi = 'Tệp XML';
						|ru = 'XML-файл';
						|en = 'XML file'; fa = 'XML file';
						|it = 'XML-файл';
						|pl = 'XML file';
						|tr = 'XML dosyası'") + "(*.xml)|*.xml"; 
	DOF.Multiselect = False;
	DOF.Title = NStr("vi = 'Lưu tệp khuôn in';
					|ru = 'Сохранение файла-макета';
					|en = 'Save template file'; fa = 'Save template file';
					|it = 'Сохранение файла-макета';
					|pl = 'Zapis pliku szablonu';
					|tr = 'Şablon dosyasının kaydedilmesi'");
	DOF.Show(New CallbackDescription("SaveToFileCompletion", ThisObject, New Structure("DOF", DOF)));
	// APK: 1348-on
	
EndProcedure

// APK: 581-off
// Check the availability of the file extension.
//
&AtClient
Procedure CheckAvailabilityOfFileExtension(NotificationOnCompletion, SuggestInstallation = True) Export
	
	AdditionalParameters = New Structure("NotificationOnCompletion, SuggestInstallation", NotificationOnCompletion, SuggestInstallation);
	Notification = New CallbackDescription("BeginAttachingFileSystemExtensionCompletion", ThisObject, AdditionalParameters);
	BeginAttachingFileSystemExtension(Notification);
	
EndProcedure
// APK: 581-on

&AtClient
Procedure BeginAttachingFileSystemExtensionCompletion(Attached, AdditionalParameters) Export
	
	If Not Attached And AdditionalParameters.SuggestInstallation Then
		Notification = New CallbackDescription("BeginInstallFileSystemExtensionCompletion", ThisObject, AdditionalParameters);
		MessageText = NStr("vi = 'Để tiếp tục làm việc, cần cài đặt phần mở rộng đối với web-client ""1C:Enterprise"". Cài đặt?';
							|ru = 'Для продолжении работы необходимо установить расширение для веб-клиента ""1С:Предприятие"". Установить?';
							|en = 'To continue, you need to install an extension for 1C:Enterprise web client. Install?'; fa = 'To continue, you need to install an extension for 1C:Enterprise web client. Install?';
							|it = 'Для продолжении работы необходимо установить расширение для веб-клиента ""1С:Предприятие"". Установить?';
							|pl = 'Aby kontynuować pracę, należy zainstalować rozszerzenie dla klienta sieci Web ""1C:Enterprise"". Zainstalować?';
							|tr = 'İşleme devam etmek için 1C:Enterprise web-client uzantısını kurmanız gerekmektedir. Kurulsun mu?'");
		ShowQueryBox(Notification, MessageText, QuestionDialogMode.YesNo); 
	EndIf;
	
	If Attached And AdditionalParameters.NotificationOnCompletion <> Undefined Then
		RunCallback(AdditionalParameters.NotificationOnCompletion, Attached);
	EndIf
	
EndProcedure

&AtClient
Procedure BeginInstallFileSystemExtensionCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		BeginInstallFileSystemExtension();
	EndIf;
	
EndProcedure

#EndRegion