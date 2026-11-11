
#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	If CallbackDescriptionOnClose.AdditionalParameters.Property("EditingAdvancedField") Then
		Items.Type.Enabled = False;
	EndIf;
	
	GridStep = CallbackDescriptionOnClose.AdditionalParameters.GridStep;
	
	FieldDetails = CallbackDescriptionOnClose.AdditionalParameters.FieldDetails;
	Top = FieldDetails.Top;
	Left = FieldDetails.Left;
	Bottom = FieldDetails.Bottom;
	Right = FieldDetails.Right;
	Description = FieldDetails.Description;
	
	If FieldDetails.Property("Value") Then
		Value = FieldDetails.Value;
	EndIf;
	
	If CallbackDescriptionOnClose.AdditionalParameters.Property("FieldToEdit") Then
		
		Type = FieldDetails.Type;
		PopulationType = FieldDetails.PopulationType;
		DefaultValue = FieldDetails.DefaultValue;
		
		If Type = "Text" Then
			Font = FieldDetails.Font;
			HorizontalPosition = FieldDetails.HorizontalPosition;
			VerticalPosition = FieldDetails.VerticalPosition;
			Multiline = FieldDetails.Multiline;
			TopFrame = FieldDetails.TopFrame;
			BottomFrame = FieldDetails.BottomFrame;
			RightFrame = FieldDetails.RightFrame;
			LeftFrame = FieldDetails.LeftFrame;
			BorderType = FieldDetails.BorderType;
			FrameWidth = FieldDetails.FrameWidth;
			BarcodeType = "EAN8";
			BarcodeLabel = False;
			CheckCharacter = False;
			FontSize = 8;
			Format = FieldDetails.Format;
			Orientation = FieldDetails.Orientation;
			Background = FieldDetails.Background;
		ElsIf Type = "Barcode" Then
			BarcodeType = FieldDetails.BarcodeType;
			CheckCharacter = FieldDetails.CheckCharacter;
			BarcodeLabel = FieldDetails.BarcodeLabel;
			FontSize = FieldDetails.SignatureFontSize;
			FrameWidth = 1;
			BorderType = "Solid";
			HorizontalPosition = "Left";
			VerticalPosition = "Top";
			Orientation = FieldDetails.Orientation;
		ElsIf Type = "Image" Then
			TopFrame = FieldDetails.TopFrame;
			BottomFrame = FieldDetails.BottomFrame;
			RightFrame = FieldDetails.RightFrame;
			LeftFrame = FieldDetails.LeftFrame;
			BorderType = FieldDetails.BorderType;
			FrameWidth = FieldDetails.FrameWidth;
			HorizontalPosition = "Left";
			VerticalPosition = "Top";
			BarcodeType = "EAN8";
			BarcodeLabel = False;
			CheckCharacter = False;
			FontSize = 8;
			Orientation = FieldDetails.Orientation;
			PictureSize = FieldDetails.PictureSize;
		ElsIf Type = "UserData" Then
			FrameWidth = 1;
			BorderType = "Solid";
			HorizontalPosition = "Left";
			VerticalPosition = "Top";
			BarcodeType = "EAN8";
			BarcodeLabel = False;
			CheckCharacter = False;
			FontSize = 8;
			Format = FieldDetails.Format;
		EndIf;
		
	ElsIf  CallbackDescriptionOnClose.AdditionalParameters.Property("ReEditing") Then
		FillPropertyValues(ThisObject, FieldDetails);
	Else
		If CallbackDescriptionOnClose.AdditionalParameters.Property("EditingAdvancedField") Then
			Type = "UserData";
		Else
			Type = "Text";
		EndIf;
		FrameWidth = 1;
		BorderType = "Solid";
		HorizontalPosition = "Left";
		VerticalPosition = "Top";
		BarcodeType = "EAN13";
		BarcodeLabel = True;
		CheckCharacter = True;
		FontSize = 8;
		PopulationType = "Parameter";
		Background = New Color(255,255,255);
	EndIf;
	
	SetVisibilityAndAvailabilityOfFields();
	
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
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CleaningField(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure TypeOnChange(Item)
	
	SetVisibilityAndAvailabilityOfFields();
	
EndProcedure

&AtClient
Procedure BarcodeLabelOnChange(Item)
	
	SetAvailabilityOfBarcodeSignatureProperties();
	
EndProcedure

&AtClient
Procedure PopulationTypeOnChange(Item)
	
	SetTypeOfValueFields();
	SetValueSelectionButtons();
	
EndProcedure

&AtClient
Procedure StartSelectingAValue(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If PopulationType = "Parameter" Then
		
		NotificationOnCompletion = New CallbackDescription("StartSelectingAValueCompletion", ThisObject);
		OpenForm("Catalog.TemplatesOfPLLabelsAndPriceTags.Form.LabelEditorFormOfDCSFieldSelection", New Structure("DCSStorageAddress", DCSStorageAddress),,,,, NotificationOnCompletion);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BorderTypeOnChange(Item)
	
	SetAvailabilityOfFrameThickness();
	
EndProcedure

&AtClient
Procedure FormatStartChoice(Item, ChoiceData, StandardProcessing)
	
#If Not MobileClient And Not MobileAppClient Then 
	StandardProcessing = False;
	Designer=New FormatStringWizard(Format);
	Designer.Show(New CallbackDescription("FormatStartChoiceCompletion", ThisObject));
#EndIf

EndProcedure

&AtClient
Procedure LeftTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = False;
	
	If Left + Direction*GridStep <= 150 Then
		Left = Left + Direction*GridStep;
	EndIf;
	
EndProcedure

&AtClient
Procedure RightTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = False;
	
	If Right + Direction*GridStep <= 150 Then
		Right = Right + Direction*GridStep;
	EndIf;
	
EndProcedure

&AtClient
Procedure TopTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = False;
	
	If Top + Direction*GridStep <= 150 Then
		Top = Top + Direction*GridStep;
	EndIf;
	
EndProcedure

&AtClient
Procedure BottomTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = False;
	
	If Bottom + Direction*GridStep <= 150 Then
		Bottom = Bottom + Direction*GridStep;
	EndIf;
	
EndProcedure

&AtClient
Procedure CoordinateEndOfTextInput(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	Quotient = Number(Text)/GridStep;
	If Int(Quotient) <> Quotient Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure BarcodeTypeOnChange(Item)
	
	If BarcodeType<>"Code39" Then
		CheckCharacter = True;
	EndIf;
	
	SetVisibilityOfCheckSymbolFlag();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectFile(Command)
	
	CallbackDescription = New CallbackDescription("FileSelection", ThisObject);
	// APK: 1348-off the filesystem Client module from BSP is not used
	BeginPutFileToServer(CallbackDescription,,,,, UUID);
	// APK: 1348-on
	
EndProcedure

&AtClient
Procedure SelectAFileForTheDefaultValue(Command)
	
	CallbackDescription = New CallbackDescription("SelectFileForDefaultValue", ThisObject);
	// APK: 1348-off the filesystem Client module from BSP is not used
	BeginPutFileToServer(CallbackDescription,,,,, UUID);
	// APK: 1348-on
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	ErrorsArray = Undefined;
	
	If Not CheckAttributesFilling(ErrorsArray) Then
		
		For Each CurError In ErrorsArray Do
			
			CommonCELClient.MessageToUser(CurError);
			
		EndDo;
		
		Return;
		
	EndIf;
	
	GenerateDescriptionOfClosureNotification();
	Close(DialogReturnCode.OK);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetValueSelectionButtons()
	
	Items.SelectFile.Visible = (Type="Image") And (PopulationType="Constant");
	Items.SelectAFileForTheDefaultValue.Visible = (Type="Image") And (PopulationType="Parameter");
	
EndProcedure

&AtClient
Procedure SetVisibilityOfCheckSymbolFlag()
	
	If BarcodeType="Code39" Then
		Items.CheckCharacter.Visible = True;
	Else
		Items.CheckCharacter.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetVisibilityAndAvailabilityOfFields()
	
	If Type = "Barcode" Then
		
		Items.GroupCoordinates.Visible = True;
		Items.GroupFrame.Visible = False;
		Items.Font.Visible = False;
		Items.HorizontalPosition.Visible = False;
		Items.VerticalPosition.Visible = False;
		Items.Multiline.Visible = False;
		Items.Orientation.Visible = True;		
		Items.BarcodeGroup.Visible = True;
		Items.Format.Visible = False;
		Items.Background.Visible = False;
		Items.PictureSize.Visible = False;
		
		SetVisibilityOfCheckSymbolFlag();
		
	ElsIf Type = "Text" Then
		Items.GroupCoordinates.Visible = True;
		Items.GroupFrame.Visible = True;
		Items.Font.Visible = True;
		Items.HorizontalPosition.Visible = True;
		Items.VerticalPosition.Visible = True;
		Items.Multiline.Visible = True;
		Items.Orientation.Visible = True;
		Items.BarcodeGroup.Visible = False;
		Items.Format.Visible = True;
		Items.Background.Visible = True;
		Items.PictureSize.Visible = False;
	ElsIf Type = "Image" Then
		Items.GroupCoordinates.Visible = True;
		Items.GroupFrame.Visible = True;
		Items.Font.Visible = True;
		Items.HorizontalPosition.Visible = False;
		Items.VerticalPosition.Visible = False;
		Items.Multiline.Visible = False;
		Items.Orientation.Visible = True;
		Items.BarcodeGroup.Visible = False;
		Items.Format.Visible = False;
		Items.Background.Visible = False;
		Items.PictureSize.Visible = True;
	Else
		Items.GroupCoordinates.Visible = False;
		Items.GroupFrame.Visible = False;
		Items.Font.Visible = False;
		Items.HorizontalPosition.Visible = False;
		Items.VerticalPosition.Visible = False;
		Items.Multiline.Visible = False;
		Items.Orientation.Visible = False;
		Items.BarcodeGroup.Visible = False;
		Items.Format.Visible = False;
		Items.Background.Visible = False;
		Items.PictureSize.Visible = False;
	EndIf;
	
	SetValueSelectionButtons();
	SetTypeOfValueFields();
	SetAvailabilityOfBarcodeSignatureProperties();
	SetAvailabilityOfFrameThickness();
	
EndProcedure

&AtClient
Procedure SetTypeOfValueFields()
	
	Items.Value.ChoiceList.Clear();
	
	If PopulationType="Parameter" Then
		Items.Value.TextEdit = False;
		Items.Value.ChoiceButton = True;
		Items.DefaultValue.Visible = True;
	Else
		Items.Value.TextEdit = True;
		Items.Value.ChoiceButton = False;
		Items.DefaultValue.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfBarcodeSignatureProperties()
	
	Items.FontSize.Enabled = BarcodeLabel;
	
EndProcedure

&AtClient
Procedure GenerateDescriptionOfClosureNotification()
	
	CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Type", Type);
	CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Description", Description);
	CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Value", Value);
	CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("PopulationType", PopulationType);
	CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("DefaultValue", ?(PopulationType="Parameter", DefaultValue, ""));
	CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Format", Format);
	
	If Type = "Text" Then
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Top", Top+1);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Left", Left+1);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Bottom", Bottom);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Right", Right);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Multiline", Multiline);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Font", Font);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("HorizontalPosition", HorizontalPosition);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("VerticalPosition", VerticalPosition);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("TopFrame", TopFrame);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("BottomFrame", BottomFrame);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("RightFrame", RightFrame);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("LeftFrame", LeftFrame);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("BorderType", BorderType);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("FrameWidth", FrameWidth);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Orientation", Orientation);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Background", Background);
	ElsIf Type = "Barcode" Then
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Top", Top+1);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Left", Left+1);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Bottom", Bottom);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Right", Right);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("BarcodeType", BarcodeType);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("CheckCharacter", CheckCharacter);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("BarcodeLabel", BarcodeLabel);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("SignatureFontSize", FontSize);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Orientation", Orientation);
	ElsIf Type = "Image" Then
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Top", Top+1);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Left", Left+1);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Bottom", Bottom);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Right", Right);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("TopFrame", TopFrame);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("BottomFrame", BottomFrame);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("RightFrame", RightFrame);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("LeftFrame", LeftFrame);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("BorderType", BorderType);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("FrameWidth", FrameWidth);
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("Orientation", Orientation);		
		CallbackDescriptionOnClose.AdditionalParameters.FieldDetails.Insert("PictureSize", PictureSize);
	EndIf;
	
EndProcedure

&AtClient
Function CheckAttributesFilling(ErrorsArray)
	
	ErrorsArray = New Array;
	
	// Checking the field type.
	If Not ValueIsFilled(Type) Then
		ErrorText = NStr("vi = 'Chưa điền mục tin Kiểu trường.';
						|ru = 'Не заполнен реквизит Тип поля.';
						|en = 'Attribute ""Field type"" is required.'; fa = 'Attribute ""Field type"" is required.';
						|it = 'Requisito Tipo di campo non compilato.';
						|pl = 'Nie wypełniono atrybutu Typ pola.';
						|tr = 'Alan Türü özniteliği doldurulmamış.'");
		ErrorsArray.Add(ErrorText);
	EndIf;
	
	// Checking the type of filling.
	If Not ValueIsFilled(PopulationType) Then
		ErrorText = NStr("vi = 'Chưa điền mục tin Kiểu điền.';
						|ru = 'Не заполнен реквизит Тип заполнения.';
						|en = 'Attribute ""Population type"" is required.'; fa = 'Attribute ""Population type"" is required.';
						|it = 'Requisito Tipo di compilazione non compilato.';
						|pl = 'Nie wypełniono atrybutu Typ wypełniania.';
						|tr = 'Doldurulacak Tür özniteliği doldurulmamış.'");
		ErrorsArray.Add(ErrorText);
	EndIf;
	
	// Checking the value.
	If Not ValueIsFilled(Value) And PopulationType = "Parameter" Then
		ErrorText = NStr("vi = 'Chưa điền mục tin Giá trị.';
						|ru = 'Не заполнен реквизит Значение.';
						|en = 'Attribute ""Value"" is required.'; fa = 'Attribute ""Value"" is required.';
						|it = 'Requisito Valore non compilato.';
						|pl = 'Nie wypełniono atrybutu Wartość.';
						|tr = 'Değer özniteliği doldurulmamış.'");
		ErrorsArray.Add(ErrorText);
	EndIf;
	
	If Type <> "UserData" Then
		
		If Left>Right Then
			ErrorText = NStr("vi = 'Tọa độ bên trái không thể lớn hơn bên phải.';
							|ru = 'Левая координата не может быть больше правой.';
							|en = 'Left coordinate cannot be greater than the right one.'; fa = 'Left coordinate cannot be greater than the right one.';
							|it = 'La coordinata sinistra non può essere maggiore di quella destra.';
							|pl = 'Lewa koordynata nie może być mniejsza od prawej.';
							|tr = 'Sol koordinat sağ koordinattan büyük olamaz.'");
			ErrorsArray.Add(ErrorText);
		EndIf;
		
		If Top>Bottom Then
			ErrorText = NStr("vi = 'Tọa độ trên không thể lớn hơn tọa độ dưới.';
							|ru = 'Верхней координата не может быть больше нижней.';
							|en = 'The top coordinate cannot be greater than the bottom coordinate.'; fa = 'The top coordinate cannot be greater than the bottom coordinate.';
							|it = 'La coordinata superiore non può essere maggiore di quella inferiore.';
							|pl = 'Górna koordynata nie może być większa od dolnej.';
							|tr = 'Üst koordinat alt koordinattan büyük olamaz.'");
			ErrorsArray.Add(ErrorText);
		EndIf;
		
	EndIf;
	
	If Type = "Text" Then
		
		// Checking the position of the horizon.
		If Not ValueIsFilled(HorizontalPosition) Then
			ErrorText = NStr("vi = 'Chưa điền mục tin Vị trí nằm ngang.';
							|ru = 'Не заполнен реквизит Горизонтальное положение.';
							|en = 'Attribute ""Horizontal position"" is required.'; fa = 'Attribute ""Horizontal position"" is required.';
							|it = 'Requisito Posizione orizzontale non compilato.';
							|pl = 'Nie wypełniono atrybutu Położenie w poziomie.';
							|tr = 'Yatay pozisyon özniteliği doldurulmamış.'");
			ErrorsArray.Add(ErrorText);
		EndIf;
		
		// Checking the position of the vertical.
		If Not ValueIsFilled(VerticalPosition) Then
			ErrorText = NStr("vi = 'Chưa điền mục tin Vị trí thằng đứng.';
							|ru = 'Не заполнен реквизит Вертикальное положение.';
							|en = 'Attribute ""Vertical position"" is required.'; fa = 'Attribute ""Vertical position"" is required.';
							|it = 'Requisito Posizione verticale non compilato.';
							|pl = 'Nie wypełniono atrybutu Położenie w pionie.';
							|tr = 'Dikey pozisyon özniteliği doldurulmamış.'");
			ErrorsArray.Add(ErrorText);
		EndIf;
		
	ElsIf Type = "Barcode" Then
		
		// Checking the type barcode.
		If Not ValueIsFilled(BarcodeType) Then
			ErrorText = NStr("vi = 'Chưa điền mục tin Kiểu mã vạch.';
							|ru = 'Не заполнен реквизит Тип штрихкода.';
							|en = 'Attribute ""Barcode type"" is required.'; fa = 'Attribute ""Barcode type"" is required.';
							|it = 'Requisito Tipo di codice a barre non compilato.';
							|pl = 'Nie wypełniono atrybutu Typ kodu kreskowego.';
							|tr = 'Barkod Türü özniteliği doldurulmamış.'");
			ErrorsArray.Add(ErrorText);
		EndIf;
		
		// Checking the size of the signature.
		If BarcodeLabel Then
			If Not ValueIsFilled(FontSize) Then
				ErrorText = NStr("vi = 'Chưa điền mục tin Kích thước phông chữ ký.';
								|ru = 'Не заполнен реквизит Размер шрифта подписи.';
								|en = 'Attribute ""Signature font size"" is required.'; fa = 'Attribute ""Signature font size"" is required.';
								|it = 'Requisito Dimensione del carattere della firma non compilato.';
								|pl = 'Nie wypełniono atrybutu Rozmiar czcionki podpisu.';
								|tr = 'İmza yazı tipi ebatı özniteliği doldurulmamış.'");
				ErrorsArray.Add(ErrorText);
			EndIf;
		EndIf;
		
	EndIf;
	
	If Type = "Text" Or Type = "Image" Then
		
		If TopFrame Or LeftFrame Or BottomFrame Or RightFrame Then
			
			// Checking the frame type.
			If Not ValueIsFilled(BorderType) Then
				ErrorText = NStr("vi = 'Chưa điền mục tin Kiểu khung.';
								|ru = 'Не заполнен реквизит Тип рамки.';
								|en = 'Attribute ""Frame type"" is required.'; fa = 'Attribute ""Frame type"" is required.';
								|it = 'Requisito Tipo di cornice non compilato.';
								|pl = 'Nie wypełniono atrybutu Typ ramki.';
								|tr = 'Çerçeve Türü özniteliği doldurulmamış.'");
				ErrorsArray.Add(ErrorText);
			EndIf;
			
			// Checking the thickness of the frame.
			If Not ValueIsFilled(FrameWidth) Then
				ErrorText = NStr("vi = 'Chưa điền mục tin Độ dày khung.';
								|ru = 'Не заполнен реквизит Толщина рамки.';
								|en = 'Attribute ""Frame width"" is required.'; fa = 'Attribute ""Frame width"" is required.';
								|it = 'Requisito Spessore cornice non compilato.';
								|pl = 'Nie wypełniono atrybutu Grubość ramki.';
								|tr = 'Çerçeve Kalınlığı özniteliği doldurulmamış.'");
				ErrorsArray.Add(ErrorText);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return ErrorsArray.Count() = 0;
	
EndFunction

&AtClient
Procedure SetAvailabilityOfFrameThickness()
	
	If BorderType = "Double" Then
		FrameWidth = 1;
		Items.FrameWidth.Enabled = False;
	Else
		Items.FrameWidth.Enabled = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure FormatStartChoiceCompletion(Text, AdditionalParameters) Export
	
	If Text <> Undefined Then
		Format = Text;
	EndIf;
	
EndProcedure

&AtClient
Procedure StartSelectingAValueCompletion(Result, AdditionalParameters) Export
	
	If Result<>Undefined Then
		Value = Result;
	EndIf;
	
EndProcedure

&AtClient
Procedure FileSelection(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	BinaryPictureData = GetFromTempStorage(Result.Address);
	Base64Row = Base64String(BinaryPictureData);
	Base64Row = StrReplace(Base64Row, Chars.LF, "");
	Value = StrReplace(Base64Row, Chars.CR, "");
	
EndProcedure

&AtClient
Procedure SelectFileForDefaultValue(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	BinaryPictureData = GetFromTempStorage(Result.Address);
	Base64Row = Base64String(BinaryPictureData);
	Base64Row = StrReplace(Base64Row, Chars.LF, "");
	DefaultValue = StrReplace(Base64Row, Chars.CR, "");
	
EndProcedure

#EndRegion