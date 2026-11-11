///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// A blank structure for filling the "BarcodeParameters" parameter that is used for receiving a barcode image.
// 
// Returns:
//   Structure:
//   * Width - Number - width of a barcode image.
//   * Height - Number - height of a barcode image.
//   * CodeType - Number - The barcode format.
//       Valid values are:
//      99 - Identify automatically
//      0 - EAN8
//      1 - EAN13
//      2 - EAN128
//      3 - Code39
//      4 - Code128
//      5 - Code16k
//      6 - PDF417
//      7 - Standart (Industrial) 2 of 5
//      8 - Interleaved 2 of 5
//      9 - Code39 Extension
//      10 - Code93
//      11 - ITF14
//      12 - RSS14
//      14 - EAN13AddOn2
//      15 - EAN13AddOn5
//      16 - QR
//      17 - GS1DataBarExpandedStacked
//      18 - Datamatrix ASCII
//      19 - Datamatrix BASE256
//      20 - Datamatrix TEXT
//      21 - Datamatrix C40
//      22 - Datamatrix X12
//      23 - Datamatrix EDIFACT
//      24 - Datamatrix GS1ASCII      
//      25 - Aztec      
//   * TextVisible - Boolean - display the HRI text for a barcode.
//   * FontSize - Number - font size of the HRI text for a barcode.
//   * CanvasRotation - Number - rotation angle.
//      Possible values: 0, 90, 180, 270.
//   * Barcode - String - a barcode value as a row or Base64.
//   * InputDataType - Number - input data type 
//      Possible values: 0 - Row, 1 - Base64
//   * BgTransparent - Boolean - transparent background of a barcode image.
//   * Inverted - Boolean -  The colors of the WK pixels will be reversed.       
//   * QRErrorCorrectionLevel - Number - correction level of the QR barcode.
//      Possible values: 0 - L, 1 - M, 2 - Q, 3 - H.
//   * Zoomable - Boolean -  scale a barcode image.
//   * MaintainAspectRatio - Boolean - save proportions of a barcode image.                                                              
//   * VerticalAlignment - Number - vertical alignment of a barcode.
//      Possible values: 1 - Top, 2 - Center, 3 - Bottom
//   * GS1DatabarRowCount - Number - a number of rows in the GS1Databar barcode.
//   * RemoveExtraBackground - Boolean
//   * LogoImage - String - a string with base64 presentation of a PNG logo image.
//   * LogoSizePercentFromBarcode - Number - a percentage of the generated QR code to add a logo.
//
Function BarcodeGenerationParameters() Export
	
	BarcodeParameters = New Structure;
	BarcodeParameters.Insert("Width"            , 100);
	BarcodeParameters.Insert("Height"            , 100);
	BarcodeParameters.Insert("CodeType"           , 99);
	BarcodeParameters.Insert("TextVisible"   , True);
	BarcodeParameters.Insert("FontSize"      , 12); 
	BarcodeParameters.Insert("FontName"); 
	BarcodeParameters.Insert("CanvasRotation"      , 0);
	BarcodeParameters.Insert("Barcode"          , "");
	BarcodeParameters.Insert("BgTransparent"     , True);
	BarcodeParameters.Insert("Inverted"      , False);
	BarcodeParameters.Insert("QRErrorCorrectionLevel", 1);
	BarcodeParameters.Insert("Zoomable"           , False);
	BarcodeParameters.Insert("MaintainAspectRatio"       , False);
	BarcodeParameters.Insert("VerticalAlignment" , 1); 
	BarcodeParameters.Insert("GS1DatabarRowCount", 2);
	BarcodeParameters.Insert("InputDataType", 0);
	BarcodeParameters.Insert("RemoveExtraBackground" , False); 
	BarcodeParameters.Insert("LogoImage");
	BarcodeParameters.Insert("LogoSizePercentFromBarcode");       
	BarcodeParameters.Insert("NewChallengeComponents", False);  
	
	Return BarcodeParameters;
	
EndFunction                      

// Barcode image generation.
//
// Parameters: 
//   BarcodeParameters - See BarcodeGeneration.BarcodeGenerationParameters.
//
// Returns: 
//   Structure:
//      Result - Boolean - barcode generation result.
//      BinaryData - BinaryData - binary data of a barcode image.
//      Picture - Picture - a picture with the generated barcode or UNDEFINED.
//
Function TheImageOfTheBarcode(BarcodeParameters) Export
	
	SystemInfo = New SystemInfo;
	PlatformTypeComponents = String(SystemInfo.PlatformType);
	
	AddIn = BarcodeGenerationServerCached.ToConnectAComponentGeneratingAnImageOfTheBarcode(PlatformTypeComponents);
	
	If AddIn = Undefined Then
		ModuleCommon = ModuleCommon();
		MessageText = NStr("vi = 'Lỗi kết nối thành phần in mã vạch bên ngoài.';
							|ru = 'Ошибка подключения внешней компоненты печати штрихкода.';
							|en = 'An error occurred while attaching the barcode printing add-in.'; fa = 'An error occurred while attaching the barcode printing add-in.';
							|it = 'Errore di connessione dei componenti di stampa di codici a barre esterni.';
							|pl = 'Błąd podłączenia komponentów zewnętrznych druku kodu kreskowego.';
							|tr = 'Barkod yazdırma add-in''i bağlanırken bir hata oluştu.'", ModuleCommon.DefaultLanguageCode());
	#If Not MobileAppServer Then
		WriteLogEvent(NStr("vi = 'Lỗi tạo mã vạch';
							|ru = 'Ошибка генерации штрихкода';
							|en = 'Barcode generation error'; fa = 'Barcode generation error';
							|it = 'Errore di generazione del codice a barre';
							|pl = 'Błąd generacji kodu kreskowego';
							|tr = 'Barkod oluşturma hatası'", 
			ModuleCommon.DefaultLanguageCode()),
			EventLogLevel.Error,,, 
			MessageText);
	#EndIf
		Raise MessageText;
	EndIf;
	
	If BarcodeParameters.Property("NewChallengeComponents") And BarcodeParameters.NewChallengeComponents Then
		Return PrepareABarcodeImage(AddIn, BarcodeParameters); 
	Else
		Return PrepareBarcodeImageOfProperty(AddIn, BarcodeParameters); 
	EndIf;
	 
EndFunction

// Returns binary data for generating a QR code.
//
// Parameters:
//  QRString         - String - data to be placed in the QR code.
//
//  CorrectionLevel - Number - an image defect level, at which it is still possible to completely recognize this QR
//                             code.
//                     The parameter must have an integer type and have one of the following possible values:
//                     0 (7% defect allowed), 1 (15% defect allowed), 2 (25% defect allowed), 3 (35% defect allowed).
//
//  Size           - Number - determines the size of the output image side, in pixels.
//                     If the smallest possible image size is greater than this parameter, the code is not generated.
//
// Returns:
//  BinaryData  - a buffer that contains the bytes of the QR code image in PNG format.
// 
// Example:
//  
//  Print a QR code containing information encrypted according to UFEBM.
//
//  QRString = PrintManagement.UFEBMFormatString(PaymentDetails);
//  ErrorText = "";
//  QRCodeData = PrintManagement.QRCodeData(QRString, 0, 190, ErrorText);
//  If Not IsBlankString(ErrorText)
//      Common.MessageToUser(ErrorText);
//  EndIf;
//
//  QRCodePicture = New Picture(QRCodeData);
//  TemplateArea.Pictures.QRCode.Picture = QRCodePicture;
//
Function QRCodeData(QRString, CorrectionLevel, Size) Export
	
	BarcodeParameters = BarcodeGenerationParameters();
	BarcodeParameters.Width = Size;
	BarcodeParameters.Height = Size;
	BarcodeParameters.Barcode = QRString;
	BarcodeParameters.QRErrorCorrectionLevel = CorrectionLevel;
	BarcodeParameters.CodeType = 16; // QR
	BarcodeParameters.RemoveExtraBackground = True;
	
	Try
		TheResultOfTheFormationOfBarcode = TheImageOfTheBarcode(BarcodeParameters);
		BinaryPictureData = TheResultOfTheFormationOfBarcode.BinaryData;
	Except
	#If Not MobileAppServer Then
		ModuleCommon = ModuleCommon();
		WriteLogEvent(NStr("vi = 'Lỗi tạo mã vạch';
							|ru = 'Ошибка генерации штрихкода';
							|en = 'Barcode generation error'; fa = 'Barcode generation error';
							|it = 'Errore di generazione del codice a barre';
							|pl = 'Błąd generacji kodu kreskowego';
							|tr = 'Barkod oluşturma hatası'", 
			ModuleCommon.DefaultLanguageCode()),
			EventLogLevel.Error,,, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	#EndIf
	EndTry;
	
	Return BinaryPictureData;
	
EndFunction

#EndRegion

#Region Internal

// Attaches the add-in.
//
// Returns: 
//   AddInObject
//   Undefined - if failed to import the add-in.
//
Function ToConnectAComponentGeneratingAnImageOfTheBarcode() Export
	
	AddIn = Undefined;
	ObjectName = ComponentDetails().ObjectName;
	FullTemplateName = ComponentDetails().FullTemplateName;
	
	ModuleCommon = ModuleCommon();
	If ModuleCommon.SubsystemExists("EquipmentSupport") Then
		// Attach the add-in via PEL.
		ModuleExternalComponentsOfBPO = ModuleCommon.CommonModule("AddInsCEL");
		AddIn = ModuleExternalComponentsOfBPO.AttachAddInSSL(ObjectName, FullTemplateName);
	Else
		// Attach the add-in with SSL.
		// Call SSL.
#If Not MobileAppServer Then
		SetSafeModeDisabled(True);
		If ModuleCommon.SeparatedDataUsageAvailable() Then
			If ModuleCommon.SubsystemExists("StandardSubsystems.AddIns") Then   
				ExternalComponentsServerModule = ModuleCommon.CommonModule("AddInsServer");
				ConnectionParameters = ExternalComponentsServerModule.ConnectionParameters();
				ConnectionResult = ExternalComponentsServerModule.AttachAddInSSL(ObjectName);
				If ConnectionResult.Attached Then
					AddIn = ConnectionResult.Attachable_Module;
				EndIf;
			EndIf;
		EndIf;
		If AddIn = Undefined Then 
			AddIn = ModuleCommon.AttachAddInFromTemplate(ObjectName, FullTemplateName);
		EndIf;
#EndIf
		// End Call SSL
	EndIf;
	
	If AddIn = Undefined Then 
		Return Undefined;
	EndIf;
	
	// Let's set the main parameters of the component.
	
	// If the system has a default font installed.
	// If the font is not found, the "Default" font built into the barcode generation VC will be used.
	If AddIn.FindFont(DefaultFont()) Then
		// Set as the picture font.
		AddIn.Font = DefaultFont();
	EndIf;
	// Set the font size.
	AddIn.FontSize = 12;
	
	Return AddIn;
	
EndFunction

// Details of attaching the barcode print add-in.
//
// Returns:
//  Structure:
//   * FullTemplateName - String
//   * ObjectName      - String
//
Function ComponentDetails() Export
	
	Parameters = New Structure;
	Parameters.Insert("ObjectName", "Barcode");
	Parameters.Insert("FullTemplateName", "CommonTemplate.BarcodePrintingAddIn");
	Return Parameters;
	
EndFunction

#EndRegion

#Region Private          

// Returns the default font name used to generate labels in the code.
//
// Returns: 
//   String - Font name
//
Function DefaultFont()
	
	FontName = "Roboto";
	Return FontName;
	
EndFunction

// Prepare a barcode image.
//
// Parameters: 
//   AddIn - See BarcodeGenerationServerCached.ToConnectAComponentGeneratingAnImageOfTheBarcode
//   BarcodeParameters - See BarcodeGeneration.BarcodeGenerationParameters
//
// Returns: 
//   Structure:
//      Result - Boolean - a barcode generation result.
//      BinaryData - BinaryData - binary data of a barcode image.
//      Picture - Picture - a picture with the generated barcode or UNDEFINED.
//
Function PrepareABarcodeImage(AddIn, BarcodeParameters)
	
	XMLWriter = New XMLWriter; 
	XMLWriter.SetString("UTF-8");
	XMLWriter.WriteXMLDeclaration();
	
	XMLWriter.WriteStartElement("MakeBarcode");
	XMLWriter.WriteStartElement("Parameters");   
	
	// Default font.
	XMLWriter.WriteStartElement("Font");   
	XMLWriter.WriteText(AddIn.Font);
	XMLWriter.WriteEndElement();
	// Image width in pixels.	  
	TheWidthOfTheBarcode = ?(BarcodeParameters.Width <= 0, 1, Round(BarcodeParameters.Width));
	XMLWriter.WriteStartElement("Width");   
	XMLWriter.WriteText(String(TheWidthOfTheBarcode));
	XMLWriter.WriteEndElement();
	// Image height in pixels.
	TheHeightOfTheBarcode = ?(BarcodeParameters.Height <= 0, 1, Round(BarcodeParameters.Height));
	XMLWriter.WriteStartElement("Height");   
	XMLWriter.WriteText(String(TheHeightOfTheBarcode));
	XMLWriter.WriteEndElement();
	// Transparent background flag.
	XMLWriter.WriteStartElement("BgTransparent");   
	XMLWriter.WriteText(XMLString(BarcodeParameters.BgTransparent));
	XMLWriter.WriteEndElement();
	// Indicates if the generator should crop the image border.
	XMLWriter.WriteStartElement("RemoveExeedBackgroud");   
	XMLWriter.WriteText(XMLString(BarcodeParameters.RemoveExtraBackground));
	XMLWriter.WriteEndElement();
	// Rotation angle.     
	CanvasRotation = Number(?(BarcodeParameters.Property("CanvasRotation"), BarcodeParameters.CanvasRotation, 0));
	XMLWriter.WriteStartElement("CanvasRotation");   
	XMLWriter.WriteText(XMLString(CanvasRotation));
	XMLWriter.WriteEndElement();
	// QR code error correction levels: 0 - L, 1 - M, 2 - Q, 3 - H.    
	QRErrorCorrectionLevel = Number(?(BarcodeParameters.Property("QRErrorCorrectionLevel"), BarcodeParameters.QRErrorCorrectionLevel, 1));
	XMLWriter.WriteStartElement("QRErrorCorrectionLevel");   
	XMLWriter.WriteText(XMLString(QRErrorCorrectionLevel));
	XMLWriter.WriteEndElement();
	// Barcode title display flag.
	XMLWriter.WriteStartElement("TextVisible");   
	XMLWriter.WriteText(XMLString(BarcodeParameters.TextVisible));
	XMLWriter.WriteEndElement();
	// Font size in pixels.
	XMLWriter.WriteStartElement("FontSize");   
	XMLWriter.WriteText(XMLString(Number(BarcodeParameters.FontSize)));
	XMLWriter.WriteEndElement();  
	// Font name 
	If BarcodeParameters.Property("FontName") And Not IsBlankString(BarcodeParameters.FontName) Then
		XMLWriter.WriteStartElement("Font");   
		XMLWriter.WriteText(XMLString(BarcodeParameters.FontName));
		XMLWriter.WriteEndElement();  
	EndIf;                        
	// Vertical alignment of the barcode on the generated image: 1 - on the top edge, 2 - in the center, 3 - on the bottom edge.
	XMLWriter.WriteStartElement("CodeVerticalAlign");   
	XMLWriter.WriteText(XMLString(Number(BarcodeParameters.VerticalAlignment)));
	XMLWriter.WriteEndElement();   
	// Number of rows in GS1 Databar Expanded Stacked.
	XMLWriter.WriteStartElement("GS1DatabarRowCount");   
	XMLWriter.WriteText(XMLString(Number(BarcodeParameters.GS1DatabarRowCount)));
	XMLWriter.WriteEndElement();
	// The colors of the WK pixels will be reversed.  
	If BarcodeParameters.Property("Inverted") Then
		XMLWriter.WriteStartElement("Inverted");   
		XMLWriter.WriteText(XMLString(BarcodeParameters.Inverted));
		XMLWriter.WriteEndElement();          
	EndIf;                        
	// Barcode type is QR code.
	If BarcodeParameters.CodeType = 16 Then 
		If ValueIsFilled(BarcodeParameters.LogoImage) Then 
			XMLWriter.WriteStartElement("LogoImageBase64");   
			XMLWriter.WriteText(XMLString(BarcodeParameters.LogoImage));
			XMLWriter.WriteEndElement();
		EndIf;
		If Not IsBlankString(BarcodeParameters.LogoSizePercentFromBarcode) Then 
			XMLWriter.WriteStartElement("LogoSizePercentFromBarcode");   
			XMLWriter.WriteText(XMLString(Number(BarcodeParameters.LogoSizePercentFromBarcode)));
			XMLWriter.WriteEndElement();
		EndIf;
	EndIf;                            
	// Define a barcode type.
	AutoBarcodeType = (BarcodeParameters.CodeType = 99);
	XMLWriter.WriteStartElement("CodeAuto");   
	XMLWriter.WriteText(XMLString(AutoBarcodeType));
	XMLWriter.WriteEndElement();
	If Not AutoBarcodeType Then          
		XMLWriter.WriteStartElement("CodeType");   
		XMLWriter.WriteText(XMLString(Number(BarcodeParameters.CodeType)));
		XMLWriter.WriteEndElement();
	EndIf;                     
	// ECL
	XMLWriter.WriteStartElement("ECL");   
	XMLWriter.WriteText("1");
	XMLWriter.WriteEndElement();
	// Barcode data type.
	XMLWriter.WriteStartElement("InputDataType");   
	XMLWriter.WriteText(XMLString(Number(BarcodeParameters.InputDataType)));
	XMLWriter.WriteEndElement();
	// Barcode value
	XMLWriter.WriteStartElement("CodeValue");   
	XMLWriter.WriteText(XMLString(String(BarcodeParameters.Barcode)));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	XMLWriter.WriteEndElement();
	
	XMLGenerationParameters = XMLWriter.Close();
	
	XMLResult = "";
	AddIn.MakeBarcode(XMLGenerationParameters, XMLResult);
	
	// Result. 
	OperationResult = New Structure();
	OperationResult.Insert("Result", False);
	OperationResult.Insert("BinaryData");
	OperationResult.Insert("Picture");
	
	If Not IsBlankString(XMLResult) Then
		XMLReader = New XMLReader; 
		XMLReader.SetString(XMLResult);
		XMLReader.MoveToContent();
		ParameterAttributes = Undefined;
		If XMLReader.Name = "MakeBarcodeResult" And XMLReader.NodeType = XMLNodeType.StartElement Then
			While XMLReader.Read() Do  
				If XMLReader.Name = "Result" And XMLReader.NodeType = XMLNodeType.StartElement And XMLReader.Read() Then
					OperationResult.Result = Number(XMLReader.Value) = 0;
				ElsIf XMLReader.Name = "ImageBase64" And XMLReader.NodeType = XMLNodeType.StartElement And XMLReader.Read() Then  
					PictureBase64 = XMLReader.Value;    
					BinaryPictureData = Base64Value(PictureBase64);   
					// If the picture is generated successfully.
					If BinaryPictureData <> Undefined Then
						OperationResult.BinaryData = BinaryPictureData;
						OperationResult.Picture = New Picture(BinaryPictureData); // Generate from binary data.
					EndIf;
				EndIf; 
			EndDo;
		EndIf;  
	EndIf; 
	
	Return OperationResult;
	
EndFunction

// Prepare a barcode image.
//
// Parameters: 
//   AddIn - See BarcodeGenerationServerCached.ToConnectAComponentGeneratingAnImageOfTheBarcode
//   BarcodeParameters - See BarcodeGeneration.BarcodeGenerationParameters
//
// Returns: 
//   Structure:
//      Result - Boolean - Generation success flag.
//      BinaryData - BinaryData - Binary data of a barcode image.
//      Picture - Picture - Barcode image or "Undefined".
//
Function PrepareBarcodeImageOfProperty(AddIn, BarcodeParameters)
	
	// Result. 
	OperationResult = New Structure();
	OperationResult.Insert("Result", False);
	OperationResult.Insert("BinaryData");
	OperationResult.Insert("Picture");
	
	// Specify the size of the picture being generated.
	TheWidthOfTheBarcode = Round(BarcodeParameters.Width);
	TheHeightOfTheBarcode = Round(BarcodeParameters.Height);
	If TheWidthOfTheBarcode <= 0 Then
		TheWidthOfTheBarcode = 1
	EndIf;
	If TheHeightOfTheBarcode <= 0 Then
		TheHeightOfTheBarcode = 1
	EndIf;
	AddIn.Width = TheWidthOfTheBarcode;
	AddIn.Height = TheHeightOfTheBarcode;
	AddIn.CodeAuto = False;
	
	TimeBarcode = String(BarcodeParameters.Barcode); // Convert into a string explicitly.
	
	If BarcodeParameters.CodeType = 99 Then
		AddIn.CodeAuto = True;
	Else
		AddIn.CodeAuto = False;
		AddIn.CodeType = BarcodeParameters.CodeType;
	EndIf;
	
	If BarcodeParameters.Property("Transparent") Then
		AddIn.BgTransparent = BarcodeParameters.BgTransparent;
	EndIf;
	
	If BarcodeParameters.Property("InputDataType") Then
		AddIn.InputDataType = BarcodeParameters.InputDataType;
	EndIf;
	
	If BarcodeParameters.Property("GS1DatabarRowCount") Then
		AddIn.GS1DatabarRowCount = BarcodeParameters.GS1DatabarRowCount;
	EndIf;
	
	If BarcodeParameters.Property("RemoveExtraBackground") Then
		AddIn.RemoveExtraBackground = BarcodeParameters.RemoveExtraBackground;
	EndIf;
	
	If BarcodeParameters.Property("Inverted") Then      
		Try
			AddIn.Inverted = BarcodeParameters.Inverted;    
		Except  
		#If Not MobileAppServer Then
			ModuleCommon = ModuleCommon();
			WriteLogEvent(NStr("vi = 'Đang sử dụng phiên bản cũ của cấu phần khởi tạo mã vạch';
								|ru = 'Используется старая версия компоненты генерации штрихкода';
								|en = 'The old version of the barcode generation add-in is used'; fa = 'The old version of the barcode generation add-in is used';
								|it = 'Используется старая версия компоненты генерации штрихкода';
								|pl = 'The old version of the barcode generation add-in is used';
								|tr = 'Barkod oluşturma bileşeninin eski bir sürümü kullanılıyor'", 
				ModuleCommon.DefaultLanguageCode()),
				EventLogLevel.Error,,, 
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		#EndIf
		EndTry
	EndIf;                        
	
	AddIn.TextVisible = BarcodeParameters.TextVisible;
	// Generate a barcode picture.
	AddIn.CodeValue = TimeBarcode;
	// Barcode rotation angle.
	AddIn.CanvasRotation = ?(BarcodeParameters.Property("CanvasRotation"), BarcodeParameters.CanvasRotation, 0);
	// QR code error correction levels (L=0, M=1, Q=2, H=3).
	AddIn.QRErrorCorrectionLevel = ?(BarcodeParameters.Property("QRErrorCorrectionLevel"), BarcodeParameters.QRErrorCorrectionLevel, 1);
	
	// Intended for compatibility with the previous versions of Peripheral Equipment Library.
	If Not BarcodeParameters.Property("Zoomable")
		Or (BarcodeParameters.Property("Zoomable") And BarcodeParameters.Zoomable) Then
		
		If Not BarcodeParameters.Property("MaintainAspectRatio")
				Or (BarcodeParameters.Property("MaintainAspectRatio") And Not BarcodeParameters.MaintainAspectRatio) Then
			// If the specified width is less than the minimal for this barcode.
			If AddIn.Width < AddIn.CodeMinWidth Then
				AddIn.Width = AddIn.CodeMinWidth;
			EndIf;
			// If the specified height is less than the minimal for this barcode.
			If AddIn.Height < AddIn.CodeMinHeight Then
				AddIn.Height = AddIn.CodeMinHeight;
			EndIf;
		ElsIf BarcodeParameters.Property("MaintainAspectRatio") And BarcodeParameters.MaintainAspectRatio Then
			While AddIn.Width < AddIn.CodeMinWidth 
				Or AddIn.Height < AddIn.CodeMinHeight Do
				// If the specified width is less than the minimal for this barcode.
				If AddIn.Width < AddIn.CodeMinWidth Then
					AddIn.Width = AddIn.CodeMinWidth;
					AddIn.Height = Round(AddIn.CodeMinWidth / TheWidthOfTheBarcode) * TheHeightOfTheBarcode;
				EndIf;
				// If the specified height is less than the minimal for this barcode.
				If AddIn.Height < AddIn.CodeMinHeight Then
					AddIn.Height = AddIn.CodeMinHeight;
					AddIn.Width = Round(AddIn.CodeMinHeight / TheHeightOfTheBarcode) * TheWidthOfTheBarcode;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	// CodeVerticalAlignment: 1 - top, 2 - center, 3 - bottom.
	If BarcodeParameters.Property("VerticalAlignment") And (BarcodeParameters.VerticalAlignment > 0) Then
		AddIn.CodeVerticalAlign = BarcodeParameters.VerticalAlignment;
	EndIf;
	
	If BarcodeParameters.Property("FontSize") And (BarcodeParameters.TextVisible)
		And (BarcodeParameters.FontSize > 0) And (AddIn.FontSize <> BarcodeParameters.FontSize) Then
			AddIn.FontSize = BarcodeParameters.FontSize;
	EndIf;
	
	// Font name 
	If BarcodeParameters.Property("FontName") And (BarcodeParameters.TextVisible) Then
		FontName = ?(IsBlankString(BarcodeParameters.FontName), DefaultFont(), BarcodeParameters.FontName);
		If AddIn.Font <> FontName Then
			If AddIn.FindFont(FontName) Then
				AddIn.Font = FontName;
			Else
				AddIn.Font = DefaultFont();
			EndIf;
		EndIf;
	EndIf;                        
	
	If BarcodeParameters.CodeType = 16 Then // QR
		If BarcodeParameters.Property("LogoImage") And ValueIsFilled(BarcodeParameters.LogoImage) Then 
			AddIn.LogoImage = BarcodeParameters.LogoImage;    
		Else
			AddIn.LogoImage = "";
		EndIf;
		If BarcodeParameters.Property("LogoSizePercentFromBarcode") And Not IsBlankString(BarcodeParameters.LogoSizePercentFromBarcode) Then 
			AddIn.LogoSizePercentFromBarcode = BarcodeParameters.LogoSizePercentFromBarcode;
		EndIf;
	EndIf;
		
	// Generate a picture.
	BinaryPictureData = AddIn.GetBarcode();
	OperationResult.Result = AddIn.Result = 0;
	// If the picture is generated successfully.
	If BinaryPictureData <> Undefined Then
		OperationResult.BinaryData = BinaryPictureData;
		OperationResult.Picture = New Picture(BinaryPictureData); // Generate from binary data.
	EndIf;
	
	Return OperationResult;
	
EndFunction

Function ModuleCommon()
	
#If Not MobileAppServer Then
	SetSafeMode(True);
#EndIf
	If Metadata.Subsystems.Find("EquipmentSupport") = Undefined Then
		// Call SSL
		Return Eval("Common");
		// The end of the BSP Challenge
	Else
		Return Eval("CommonCEL");
	EndIf;
	
EndFunction

#EndRegion