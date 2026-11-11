///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Gets the unique file name for using it in the working directory.
// If there are matches, the name is similar to "A1Order.doc".
//
Function UniqueNameByWay(Val DirectoryName, Val FileName) Export
	
	CommonClientServer.Validate(ValueIsFilled(DirectoryName),
		NStr("vi = 'Cần điền thư mục.';
			|ru = 'Каталог должен быть заполнен.';
			|en = 'Fill in the directory.'; fa = 'Fill in the directory.';
			|it = 'La directory deve essere compilata.';
			|pl = 'Katalog powinien być wypełniony.';
			|tr = 'Katalog dolu olmalıdır.'"),	"FilesOperationsInternalClientServer.UniqueNameByWay");
	
	FinalPath = "";
	
	Counter = 0;
	DoNumber = 0;
	Success = False;
	CodeOfFirstLetter = CharCode("A", 1);
	
	RandomValueGenerator = Undefined;
	
#If Not WebClient Then
	RandomValueGenerator = New RandomNumberGenerator(CurrentUniversalDateInMilliseconds());
#EndIf

	RandomOptionsCount = 26;
	
	While Not Success And DoNumber < 100 Do
		DirectoryNumber = 0;
		
#If Not WebClient Then
		DirectoryNumber = RandomValueGenerator.RandomNumber(0, RandomOptionsCount - 1);
#Else
		DirectoryNumber = CurrentUniversalDateInMilliseconds() % RandomOptionsCount;
#EndIf

		If Counter > 1 And RandomOptionsCount < 26 * 26 * 26 * 26 * 26 Then
			RandomOptionsCount = RandomOptionsCount * 26;
		EndIf;
		
		DirectoryLetters = "";
		CodeOfFirstLetter = CharCode("A", 1);
		
		While True Do
			LetterNumber = DirectoryNumber % 26;
			DirectoryNumber = Int(DirectoryNumber / 26);
			
			DirectoryCode = CodeOfFirstLetter + LetterNumber;
			
			DirectoryLetters = DirectoryLetters + Char(DirectoryCode);
			If DirectoryNumber = 0 Then
				Break;
			EndIf;
		EndDo;
		
		Subdirectory = ""; // A partial path.
		
		// Try using the root. If it fails, add A, B, … Z, … ZZZZZ, … AAAAA, … AAAAAZ, etc.
		// 
		If  Counter = 0 Then
			Subdirectory = "";
		Else
			Subdirectory = DirectoryLetters;
			DoNumber = Round(Counter / 26);
			
			If DoNumber <> 0 Then
				DoNumberString = String(DoNumber);
				Subdirectory = Subdirectory + DoNumberString;
			EndIf;
			
			If IsReservedDirectoryName(Subdirectory) Then
				Continue;
			EndIf;
			
			Subdirectory = CommonClientServer.AddLastPathSeparator(Subdirectory);
		EndIf;
		
		FullSubdirectory = DirectoryName + Subdirectory;
		
		// Creating a directory for files.
		DirectoryOnHardDrive = New File(FullSubdirectory);
		If Not DirectoryOnHardDrive.Exists() Then
			Try
				CreateDirectory(FullSubdirectory);
			Except
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể tạo thư mục ""%1"":
						|""%2"".';
						|ru = 'Не удалось создать каталог ""%1"":
						|""%2"".';
						|en = 'Cannot create the ""%1"" directory:
						| %2.'; fa = 'Cannot create the ""%1"" directory:
						| %2.';
						|it = 'Non è stato possibile creare il catalogo ""%1"":
						|""%2"".';
						|pl = 'Nie udało się utworzyć folderu ""%1"":
						|""%2"".';
						|tr = '""%1"" kataloğu oluşturulamadı:
						|""%2"".'"),
					FullSubdirectory,
					ErrorProcessing.BriefErrorDescription(ErrorInfo()) );
			EndTry;
		EndIf;
		
		AttemptFile = FullSubdirectory + FileName;
		Counter = Counter + 1;
		
		// Checking whether the file name is unique
		FileOnHardDrive = New File(AttemptFile);
		If Not FileOnHardDrive.Exists() Then  // File doesn't exist.
			FinalPath = Subdirectory + FileName;
			Success = True;
		EndIf;
	EndDo;
	
	Return FinalPath;
	
EndFunction

// Returns True if the file with such extension is in the list of extensions.
Function FileExtensionInList(ExtensionsList, FileExtention) Export
	
	FileExtentionWithoutDot = CommonClientServer.ExtensionWithoutPoint(FileExtention);
	
	ExtensionsArray = StrSplit(
		Lower(ExtensionsList), " ", False);
	
	If ExtensionsArray.Find(FileExtentionWithoutDot) <> Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

#Region ForUI

// Returns the message stating that locked files cannot be signed.
//
Function MessageAboutInvalidSigningOfLockedFile(FileRef = Undefined) Export
	
	If FileRef = Undefined Then
		Return NStr("vi = 'Không thể ký tên tệp đã bị chiếm.';
					|ru = 'Нельзя подписать занятый файл.';
					|en = 'Cannot sign the file because it is locked.'; fa = 'Cannot sign the file because it is locked.';
					|it = 'Non si può firmare un file occupato.';
					|pl = 'Nie można podpisać zajęty plik.';
					|tr = 'Kilitli dosya imzalanamıyor.'");
	Else
		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể ký tên tệp đã bị chiếm: %1.';
				|ru = 'Нельзя подписать занятый файл: %1.';
				|en = 'Cannot sign the file %1 because it is locked.'; fa = 'Cannot sign the file %1 because it is locked.';
				|it = 'Non si può firmare il file occupato: %1.';
				|pl = 'Nie można podpisać zajęty plik: %1.';
				|tr = 'Kilitli dosya imzalanamıyor: %1.'"),
			String(FileRef) );
	EndIf;
	
EndFunction

// Returns the message stating that encrypted files cannot be signed.
//
Function MessageAboutInvalidSigningOfEncryptedFile(FileRef = Undefined) Export
	
	If FileRef = Undefined Then
		Return NStr("vi = 'Không thể ký tên tệp đã mã hóa.';
					|ru = 'Нельзя подписать зашифрованный файл.';
					|en = 'Cannot sign the file because it is encrypted.'; fa = 'Cannot sign the file because it is encrypted.';
					|it = 'Non si può firmare un file cifrato.';
					|pl = 'Nie można podpisać zaszyfrowany plik.';
					|tr = 'Şifrelenmiş dosya imzalanamıyor.'");
	Else
		Return StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Không thể ký tên tệp đã mã hóa: %1.';
							|ru = 'Нельзя подписать зашифрованный файл: %1.';
							|en = 'Cannot sign the file %1 because it is encrypted.'; fa = 'Cannot sign the file %1 because it is encrypted.';
							|it = 'Non si può firmare il file cifrato: %1.';
							|pl = 'Nie można podpisać zaszyfrowany plik: %1.';
							|tr = 'Şifrelenmiş dosya imzalanamıyor: %1.'"),
						String(FileRef) );
	EndIf;
	
EndFunction

// Receive a row representing the file size. For example, to display the state when the file is transferred.
Function FileSizePresentation(Val SizeInMB) Export
	
	If SizeInMB < 0.1 Then
		SizeInMB = 0.1;
	EndIf;	
	
	SizeString = ?(SizeInMB >= 1, Format(SizeInMB, "NFD=0"), Format(SizeInMB, "NFD=1; NZ=0"));
	Return SizeString;
	
EndFunction	

// Get the index of the file icon. It is the index in the "FileIconCollection" picture.
Function IndexOfFileIcon(Val FileExtention) Export
	
	If TypeOf(FileExtention) <> Type("String")
		Or IsBlankString(FileExtention) Then
		Return 0;
	EndIf;
	
	FileExtention = CommonClientServer.ExtensionWithoutPoint(FileExtention);
	
	Extension = "." + Lower(FileExtention) + ";";
	
	If StrFind(".dt;.1cd;.cf;.cfu;", Extension) <> 0 Then
		Return 6; // 1C:Enterprise files.
		
	ElsIf Extension = ".mxl;" Then
		Return 8; // Spreadsheet files
		
	ElsIf StrFind(".txt;.log;.ini;", Extension) <> 0 Then
		Return 10; // Text files
		
	ElsIf Extension = ".epf;" Then
		Return 12; // External data processors.
		
	ElsIf StrFind(".ico;.wmf;.emf;",Extension) <> 0 Then
		Return 14; // Pictures
		
	ElsIf StrFind(".htm;.html;.url;.mht;.mhtml;",Extension) <> 0 Then
		Return 16; // HTML.
		
	ElsIf StrFind(".doc;.dot;.rtf;",Extension) <> 0 Then
		Return 18; // Microsoft Word file.
		
	ElsIf StrFind(".xls;.xlw;",Extension) <> 0 Then
		Return 20; // Microsoft Excel file.
		
	ElsIf StrFind(".ppt;.pps;",Extension) <> 0 Then
		Return 22; // Microsoft PowerPoint file.
		
	ElsIf StrFind(".vsd;",Extension) <> 0 Then
		Return 24; // Microsoft Visio file.
		
	ElsIf StrFind(".mpp;",Extension) <> 0 Then
		Return 26; // Microsoft Visio file.
		
	ElsIf StrFind(".mdb;.adp;.mda;.mde;.ade;",Extension) <> 0 Then
		Return 28; // Microsoft Access database.
		
	ElsIf StrFind(".xml;",Extension) <> 0 Then
		Return 30; // xml.
		
	ElsIf StrFind(".msg;.eml;",Extension) <> 0 Then
		Return 32; // Email message.
		
	ElsIf StrFind(".zip;.rar;.arj;.cab;.lzh;.ace;",Extension) <> 0 Then
		Return 34; // Archives.
		
	ElsIf StrFind(".exe;.com;.bat;.cmd;",Extension) <> 0 Then
		Return 36; // Executable files.
		
	ElsIf StrFind(".grs;",Extension) <> 0 Then
		Return 38; // Graphical schema.
		
	ElsIf StrFind(".geo;",Extension) <> 0 Then
		Return 40; // Geographical schema.
		
	ElsIf StrFind(".jpg;.jpeg;.jp2;.jpe;",Extension) <> 0 Then
		Return 42; // jpg.
		
	ElsIf StrFind(".bmp;.dib;",Extension) <> 0 Then
		Return 44; // bmp.
		
	ElsIf StrFind(".tif;.tiff;",Extension) <> 0 Then
		Return 46; // tif.
		
	ElsIf StrFind(".gif;",Extension) <> 0 Then
		Return 48; // gif.
		
	ElsIf StrFind(".png;",Extension) <> 0 Then
		Return 50; // png.
		
	ElsIf StrFind(".pdf;",Extension) <> 0 Then
		Return 52; // pdf.
		
	ElsIf StrFind(".odt;",Extension) <> 0 Then
		Return 54; // Open Office writer.
		
	ElsIf StrFind(".odf;",Extension) <> 0 Then
		Return 56; // Open Office math.
		
	ElsIf StrFind(".odp;",Extension) <> 0 Then
		Return 58; // Open Office Impress.
		
	ElsIf StrFind(".odg;",Extension) <> 0 Then
		Return 60; // Open Office draw.
		
	ElsIf StrFind(".ods;",Extension) <> 0 Then
		Return 62; // Open Office calc.
		
	ElsIf StrFind(".mp3;",Extension) <> 0 Then
		Return 64;
		
	ElsIf StrFind(".erf;",Extension) <> 0 Then
		Return 66; // External reports.
		
	ElsIf StrFind(".docx;",Extension) <> 0 Then
		Return 68; // Microsoft Word 2007 file (DOCX).
		
	ElsIf StrFind(".xlsx;",Extension) <> 0 Then
		Return 70; // Microsoft Excel 2007 file (XLSX).
		
	ElsIf StrFind(".pptx;",Extension) <> 0 Then
		Return 72; // Microsoft PowerPoint 2007 file (PPTX).
		
	ElsIf StrFind(".p7s;",Extension) <> 0 Then
		Return 74; // Signature file.
		
	ElsIf StrFind(".p7m;",Extension) <> 0 Then
		Return 76; // Encrypted message.
	Else
		Return 4;
	EndIf;
	
EndFunction

#EndRegion

#Region OtherItems

// For internal use only.
Procedure FillSignatureStatus(SignatureRow, CurrentDate) Export
	
	If Not ValueIsFilled(SignatureRow.SignatureValidationDate) Then
		SignatureRow.Status = "";
		Return;
	EndIf;
	
	If SignatureRow.SignatureCorrect
		And ValueIsFilled(SignatureRow.DateActionLastTimestamp)
		And SignatureRow.DateActionLastTimestamp < CurrentDate Then
		SignatureRow.Status = NStr("vi = 'Chính xác vào ngày ký';
									|ru = 'Была верна на дату подписи';
									|en = 'Was valid on the date of signature'; fa = 'Was valid on the date of signature';
									|it = 'Valida alla data di firma';
									|pl = 'Była zgodna na datę podpisu';
									|tr = 'İmzalama tarihinde geçerli idi'");
	ElsIf SignatureRow.SignatureCorrect Then
		SignatureRow.Status = NStr("vi = 'Đúng';
									|ru = 'Верна';
									|en = 'Valid'; fa = 'معتبر';
									|it = 'Corretta';
									|pl = 'Valid';
									|tr = 'Geçerli'");
	ElsIf SignatureRow.IsVerificationRequired Then
		SignatureRow.Status = NStr("vi = 'Cần kiểm tra';
									|ru = 'Требуется проверка';
									|en = 'Verification required'; fa = 'تأیید اعتبار لازم است';
									|it = 'Требуется проверка';
									|pl = 'Verification required';
									|tr = 'Doğrulama gerekli'");
	Else
		SignatureRow.Status = NStr("vi = 'Sai';
									|ru = 'Неверна';
									|en = 'Invalid'; fa = 'نامعتبر';
									|it = 'Incorretta';
									|pl = 'Invalid';
									|tr = 'Geçersiz'");
	EndIf;
		
EndProcedure

#EndRegion

#Region FilesSynchronization

// Parameters to lock a file for editing.
//
// Returns:
//   Structure:
//     * UUID - form UUID.
//     * User - CatalogRef.Users
//     * AdditionalProperties - Structure - additional properties for writing a file.
//
Function FileLockParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("UUID");
	Parameters.Insert("User");
	Parameters.Insert("AdditionalProperties");
	Parameters.Insert("RaiseException1", True);
	
	Return Parameters;
	
EndFunction

// Scanning add-in attachment details.
//
// Returns:
//  Structure:
//   * FullTemplateName - String
//   * ObjectName      - String
//
Function ComponentDetails() Export
	
	Parameters = New Structure;
	Parameters.Insert("ObjectName", "ImageScan");
	Parameters.Insert("FullTemplateName", "CommonTemplate.DocumentScanningAddIn");
	Return Parameters;
	
EndFunction

#EndRegion

#Region TextExtraction

// Extracts text in the specified encoding.
// If encoding is not specified, it calculates the encoding itself.
//
Function ExtractTextFromTextFile(FullFileName, Encoding, Cancel) Export
	
	ExtractedText = "";
	
#If Not WebClient Then
	
	// Determine encoding.
	If Not ValueIsFilled(Encoding) Then
		Encoding = Undefined;
	EndIf;
	
	Try
		EncodingForRead = ?(Encoding = "utf-8_WithoutBOM", "utf-8", Encoding);
		TextReader = New TextReader(FullFileName, EncodingForRead);
		ExtractedText = TextReader.Read();
	Except
		Cancel = True;
		ExtractedText = "";
	EndTry;
	
#EndIf
	
	Return ExtractedText;
	
EndFunction

// Extracts text from an OpenDocument file and returns it as String.
//
Function ExtractOpenDocumentText(PathToFile, Cancel) Export
	
	ExtractedText = "";
	
#If Not WebClient And Not MobileClient Then
	
	TemporaryFolderForUnzipping = GetTempFileName("");
	TemporaryZIPFile = GetTempFileName("zip"); 
	
	CopyFile(PathToFile, TemporaryZIPFile);
	File = New File(TemporaryZIPFile);
	File.SetReadOnly(False);

	Try
		Archive = New ZipFileReader();
		Archive.Open(TemporaryZIPFile);
		Archive.ExtractAll(TemporaryFolderForUnzipping, ZIPRestoreFilePathsMode.Restore);
		Archive.Close();
		XMLReader = New XMLReader();
		
		XMLReader.OpenFile(TemporaryFolderForUnzipping + "/content.xml");
		ExtractedText = ExtractTextFromXMLContent(XMLReader);
		XMLReader.Close();
	Except
		// This is not an error because the OTF extension, for example, is related both to OpenDocument format and OpenType font format.
		Archive     = Undefined;
		XMLReader = Undefined;
		Cancel = True;
		ExtractedText = "";
	EndTry;
	
	DeleteFiles(TemporaryFolderForUnzipping);
	DeleteFiles(TemporaryZIPFile);
	
#EndIf
	
	Return ExtractedText;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Extract text from the XMLReader object (that was read from an OpenDocument file).
Function ExtractTextFromXMLContent(XMLReader)
	
	ExtractedText = "";
	LastTagName = "";
	
#If Not WebClient Then
	
	While XMLReader.Read() Do
		
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			
			LastTagName = XMLReader.Name;
			
			If XMLReader.Name = "text:p" Then
				If Not IsBlankString(ExtractedText) Then
					ExtractedText = ExtractedText + Chars.LF;
				EndIf;
			EndIf;
			
			If XMLReader.Name = "text:line-break" Then
				If Not IsBlankString(ExtractedText) Then
					ExtractedText = ExtractedText + Chars.LF;
				EndIf;
			EndIf;
			
			If XMLReader.Name = "text:tab" Then
				If Not IsBlankString(ExtractedText) Then
					ExtractedText = ExtractedText + Chars.Tab;
				EndIf;
			EndIf;
			
			If XMLReader.Name = "text:s" Then
				
				AdditionString = " "; // A whitespace.
				
				If XMLReader.AttributeCount() > 0 Then
					While XMLReader.ReadAttribute() Do
						If XMLReader.Name = "text:c"  Then
							SpaceCount = Number(XMLReader.Value);
							AdditionString = "";
							For IndexOf = 0 To SpaceCount - 1 Do
								AdditionString = AdditionString + " "; // A whitespace.
							EndDo;
						EndIf;
					EndDo
				EndIf;
				
				If Not IsBlankString(ExtractedText) Then
					ExtractedText = ExtractedText + AdditionString;
				EndIf;
			EndIf;
			
		EndIf;
		
		If XMLReader.NodeType = XMLNodeType.Text Then
			
			If StrFind(LastTagName, "text:") <> 0 Then
				ExtractedText = ExtractedText + XMLReader.Value;
			EndIf;
			
		EndIf;
		
	EndDo;
	
#EndIf

	Return ExtractedText;
	
EndFunction

// Receive scanned file name of the type DM-00000012, where DM is base prefix.
//
// Parameters:
//  FileNumber  - Number - an integer, for example, 12.
//  BasePrefix - String - a base prefix, for example, DM.
//
// Returns:
//  String - scanned file name, for example, "DM-00000012".
//
Function ScannedFileName(FileNumber, BasePrefix) Export
	
	FileName = "";
	If Not IsBlankString(BasePrefix) Then
		FileName = BasePrefix + "-";
	EndIf;
	
	FileName = FileName + Format(FileNumber, "ND=9; NLZ=; NG=0");
	Return FileName;
	
EndFunction

#Region AuxiliaryProceduresAndFunctions

Function IsReservedDirectoryName(SubDirectoryName)
	
	NamesList = New Map();
	NamesList.Insert("CON", True);
	NamesList.Insert("PRN", True);
	NamesList.Insert("AUX", True);
	NamesList.Insert("NUL", True);
	
	Return NamesList[SubDirectoryName] <> Undefined;
	
EndFunction

// Initializes parameter structure to add the file.
// Use this function in FilesOperations.AppendFile and FilesOperationsInternalServerCall.AppendFile.
//
Function FileAddingOptions(AdditionalAttributes = Undefined) Export
	
	If TypeOf(AdditionalAttributes) = Type("Structure") Then
		FileAttributes = Undefined;
		AddingOptions = AdditionalAttributes;
	Else
		
		AddingOptions = New Structure;
		FileAttributes = ?(TypeOf(AdditionalAttributes) = Type("Array"),
			AdditionalAttributes,
			StringFunctionsClientServer.SplitStringIntoSubstringsArray(AdditionalAttributes, ",", True, True));
		
	EndIf;
	
	AddProperty(AddingOptions, "Author");
	AddProperty(AddingOptions, "FilesOwner");
	AddProperty(AddingOptions, "BaseName", "");
	AddProperty(AddingOptions, "ExtensionWithoutPoint", "");
	AddProperty(AddingOptions, "ModificationTimeUniversal");
	AddProperty(AddingOptions, "FilesGroup");
	AddProperty(AddingOptions, "IsInternal", False);
	
	If FileAttributes = Undefined Then
		Return AddingOptions;
	EndIf;
	
	For Each AdditionalAttribute In FileAttributes Do
		AddProperty(AddingOptions, AdditionalAttribute);
	EndDo;
	
	Return AddingOptions;
	
EndFunction

Procedure AddProperty(Collection, Var_Key, Value = Undefined)
	
	If Not Collection.Property(Var_Key) Then
		Collection.Insert(Var_Key, Value);
	EndIf;
	
EndProcedure

// Automatically determines and returns the text file encoding.
//
// Parameters:
//  DataForAnalysis - BinaryData, String - data to determine encoding or data address.
//  Extension         - String - file extension.
//
// Returns:
//  String
//
Function DetermineBinaryDataEncoding(DataForAnalysis, Extension) Export
	
	If TypeOf(DataForAnalysis) = Type("BinaryData") Then
		BinaryData = DataForAnalysis;
	ElsIf IsTempStorageURL(DataForAnalysis) Then
		BinaryData = GetFromTempStorage(DataForAnalysis);
	Else
		BinaryData = Undefined;
	EndIf;

	Encoding = Undefined;
	
	If BinaryData <> Undefined Then
		Encoding = EncodingFromBinaryData(BinaryData);
		If Not ValueIsFilled(Encoding) Then
			If StrEndsWith(Lower(Extension), "xml") Then
				Encoding = EncodingFromXMLNotification(BinaryData);
			Else
				Encoding = EncodingFromAlphabetMap(BinaryData);
			EndIf;
			
			If Lower(Encoding) = "utf-8" Then
				Encoding = Lower(Encoding) + "_WithoutBOM";
			EndIf;
			
		EndIf;
	EndIf;
	Return Encoding;
	
EndFunction

// Returns the encoding received from file binary data if 
// the file contains the BOM signature in the beginning.
//
// Parameters:
//  BinaryData - BinaryData - binary data of the file.
//
// Returns:
//  String - file encoding. If the file does not contain the BOM signature, 
//           returns an empty string.
//
Function EncodingFromBinaryData(BinaryData)

	DataReader        = New DataReader(BinaryData);
	BinaryDataBuffer = DataReader.ReadIntoBinaryDataBuffer(5);
	
	Return BOMEncoding(BinaryDataBuffer);

EndFunction

// Returns the encoding received from file binary data if 
// the file contains the XML notification.
//
// Parameters:
//  BinaryData - BinaryData- binary data of the file.
//
// Returns:
//  String - file encoding. If  
//                          the XML notification cannot be read, returns an empty string.
//
Function EncodingFromXMLNotification(BinaryData)
	
#If WebClient Then
	String = GetStringFromBinaryData(BinaryData);
	FirstTag = StrSplit(String, ">", False)[0];
	Encoding = Mid(FirstTag, StrFind(FirstTag, "encoding") + 10);
	XMLEncoding = StrSplit(Encoding, """")[0];
#Else
	BinaryDataBuffer = GetBinaryDataBufferFromBinaryData(BinaryData);
	MemoryStream = New MemoryStream(BinaryDataBuffer);
	XMLEncoding = "";
	
	XMLReader = New XMLReader;
	XMLReader.OpenStream(MemoryStream);
	Try
		XMLReader.MoveToContent();
		XMLEncoding = XMLReader.XMLEncoding;
	Except
		XMLEncoding = "";
	EndTry;
	XMLReader.Close();
	MemoryStream.Close();
#EndIf
	Return XMLEncoding;
	
EndFunction

// Returns the text encoding received from the BOM signature in the beginning.
//
// Parameters:
//  BinaryDataBuffer - Number - a collection of bytes to define encoding.
//
// Returns:
//  String - file encoding. If the file does not contain the BOM signature, 
//                       returns an empty string.
//
Function BOMEncoding(BinaryDataBuffer)
	
	ReadBytes = New Array(5);
	For IndexOf = 0 To 4 Do
		If IndexOf < BinaryDataBuffer.Size Then
			ReadBytes[IndexOf] = BinaryDataBuffer[IndexOf];
		Else
			ReadBytes[IndexOf] = NumberFromHexString("0xA5");
		EndIf;
	EndDo;
	
	If ReadBytes[0] = NumberFromHexString("0xFE")
		And ReadBytes[1] = NumberFromHexString("0xFF") Then
		Encoding = "UTF-16BE";
	ElsIf ReadBytes[0] = NumberFromHexString("0xFF")
		And ReadBytes[1] = NumberFromHexString("0xFE") Then
		If ReadBytes[2] = NumberFromHexString("0x00")
			And ReadBytes[3] = NumberFromHexString("0x00") Then
			Encoding = "UTF-32LE";
		Else
			Encoding = "UTF-16LE";
		EndIf;
	ElsIf ReadBytes[0] = NumberFromHexString("0xEF")
		And ReadBytes[1] = NumberFromHexString("0xBB")
		And ReadBytes[2] = NumberFromHexString("0xBF") Then
		Encoding = "UTF-8";
	ElsIf ReadBytes[0] = NumberFromHexString("0x00")
		And ReadBytes[1] = NumberFromHexString("0x00")
		And ReadBytes[2] = NumberFromHexString("0xFE")
		And ReadBytes[3] = NumberFromHexString("0xFF") Then
		Encoding = "UTF-32BE";
	ElsIf ReadBytes[0] = NumberFromHexString("0x0E")
		And ReadBytes[1] = NumberFromHexString("0xFE")
		And ReadBytes[2] = NumberFromHexString("0xFF") Then
		Encoding = "SCSU";
	ElsIf ReadBytes[0] = NumberFromHexString("0xFB")
		And ReadBytes[1] = NumberFromHexString("0xEE")
		And ReadBytes[2] = NumberFromHexString("0x28") Then
		Encoding = "BOCU-1";
	ElsIf ReadBytes[0] = NumberFromHexString("0x2B")
		And ReadBytes[1] = NumberFromHexString("0x2F")
		And ReadBytes[2] = NumberFromHexString("0x76")
		And (ReadBytes[3] = NumberFromHexString("0x38")
			Or ReadBytes[3] = NumberFromHexString("0x39")
			Or ReadBytes[3] = NumberFromHexString("0x2B")
			Or ReadBytes[3] = NumberFromHexString("0x2F")) Then
		Encoding = "UTF-7";
	ElsIf ReadBytes[0] = NumberFromHexString("0xDD")
		And ReadBytes[1] = NumberFromHexString("0x73")
		And ReadBytes[2] = NumberFromHexString("0x66")
		And ReadBytes[3] = NumberFromHexString("0x73") Then
		Encoding = "UTF-EBCDIC";
	Else
		Encoding = "";
	EndIf;
	
	Return Encoding;
	
EndFunction

// Returns the most suitable text encoding obtained by comparing with the alphabet.
//
// Parameters:
//  TextData - BinaryData - binary data of the file.
//
// Returns:
//  String - file encoding.
//
Function EncodingFromAlphabetMap(TextData)
	
	Encodings = Encodings();
	Encodings.Delete(Encodings.FindByValue("utf-8_WithoutBOM"));
	
	EncodingKOI8R = Encodings.FindByValue("koi8-r");
	Encodings.Move(EncodingKOI8R, -Encodings.IndexOf(EncodingKOI8R));
	
	EncodingWin1251 = Encodings.FindByValue("windows-1251");
	Encodings.Move(EncodingWin1251, -Encodings.IndexOf(EncodingWin1251));
	
	EncodingUTF8 = Encodings.FindByValue("utf-8");
	Encodings.Move(EncodingUTF8, -Encodings.IndexOf(EncodingUTF8));
	
	CorrespondingEncoding = "";
	MaxEncodingMap = 0;
	For Each Encoding In Encodings Do
		
		EncodingMap = AlphabetMapPercentage(TextData, Encoding.Value);
		If EncodingMap > 0.95 Then
			Return Encoding.Value;
		EndIf;
		
		If EncodingMap > MaxEncodingMap Then
			CorrespondingEncoding = Encoding.Value;
			MaxEncodingMap = EncodingMap;
		EndIf;
		
	EndDo;
	
	Return CorrespondingEncoding;
	
EndFunction

Function AlphabetMapPercentage(BinaryData, EncodingToCheck)
	
	// ACC:1036-off, ACC:163-off The alphabet doesn't require spell check.
	Alphabet = "AABBBBGgDDHerHerLJZZIIYyKKLlMmNNOOPPPPSSTTUuFFXXCCHHShhShhYyYyEEYyYy"
		+ "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz"
		+ "1234567890 ";
	// ACC:1036-on, ACC:163-on
	
	AlphabetStream = New MemoryStream();
	WriteAlphabet = New DataWriter(AlphabetStream);
	WriteAlphabet.WriteLine(Alphabet, EncodingToCheck);
	WriteAlphabet.Close();
	
	AlphabetData = AlphabetStream.CloseAndGetBinaryData();
	ReadAlphabetData = New DataReader(AlphabetData);
	AlphabetBufferInEncoding = ReadAlphabetData.ReadIntoBinaryDataBuffer();
	
	IndexOf = 0;
	AlphabetChars = New Array;
	While IndexOf <= AlphabetBufferInEncoding.Size - 1 Do
		
		CurrentChar = AlphabetBufferInEncoding[IndexOf];
		
		// Cyrillic characters in UTF-8 encoding are double-byte.
		If EncodingToCheck = "utf-8"
			And (CurrentChar = 208
			Or CurrentChar = 209) Then
			
			IndexOf = IndexOf + 1;
			CurrentChar = Format(CurrentChar, "NZ=0; NG=") + Format(AlphabetBufferInEncoding[IndexOf], "NZ=0; NG=");
		EndIf;
		
		IndexOf = IndexOf + 1;
		AlphabetChars.Add(CurrentChar);
		
	EndDo;
	
	ReadTextData = New DataReader(BinaryData);
	TextDataBuffer = ReadTextData.ReadIntoBinaryDataBuffer(?(EncodingToCheck = "utf-8", 200, 100));
	TextBufferSize = TextDataBuffer.Size;
	CharsCount = TextBufferSize;
	
	IndexOf = 0;
	OccurrencesCount = 0;
	While IndexOf <= TextBufferSize - 1 Do
		
		CurrentChar = TextDataBuffer[IndexOf];
		If EncodingToCheck = "utf-8"
			And (CurrentChar = 208
			Or CurrentChar = 209) Then
			
			// If the last byte in buffer is the first byte of a double-byte character, ignore it.
			If IndexOf = TextBufferSize - 1 Then
				Break;
			EndIf;
			
			IndexOf = IndexOf + 1;
			CharsCount = CharsCount - 1;
			CurrentChar = Format(CurrentChar, "NZ=0; NG=") + Format(TextDataBuffer[IndexOf], "NZ=0; NG=");
			
		EndIf;
		
		IndexOf = IndexOf + 1;
		If AlphabetChars.Find(CurrentChar) <> Undefined Then
			OccurrencesCount = OccurrencesCount + 1;
		EndIf;
		
	EndDo;
	
	Return ?(CharsCount = 0, 100, OccurrencesCount/CharsCount);
	
EndFunction

// Returns a table of encoding names.
//
// Returns:
//   ValueList:
//     * Value - String - for example, "ibm852".
//     * Presentation - String - for example, "ibm852 (Central European DOS)".
//
Function Encodings() Export

	EncodingsList = New ValueList;
	
	EncodingsList.Add("ibm852",       NStr("vi = 'IBM852 (DOS Trung Âu)';
											|ru = 'IBM852 (Центральноевропейская DOS)';
											|en = 'IBM852 (Central European DOS)'; fa = 'IBM852 (Central European DOS)';
											|it = 'ibm852 (DOS dell''Europa centrale)';
											|pl = 'IBM852 (Europa środkowa DOS)';
											|tr = 'IBM852 (Orta Avrupa DOS)'"));
	EncodingsList.Add("ibm866",       NStr("vi = 'IBM866 (DOS Cyrillic)';
											|ru = 'IBM866 (Кириллица DOS)';
											|en = 'IBM866 (Cyrillic DOS)'; fa = 'IBM866 (Cyrillic DOS)';
											|it = 'ibm866 (Alfabeto cirillico DOS)';
											|pl = 'IBM866 (Cyrylica DOS)';
											|tr = 'IBM866 (Kiril DOS)'"));
	EncodingsList.Add("iso-8859-1",   NStr("vi = 'ISO-8859-1 (ISO Tây Âu)';
											|ru = 'ISO-8859-1 (Западноевропейская ISO)';
											|en = 'ISO-8859-1 (Western European ISO)'; fa = 'ISO-8859-1 (Western European ISO)';
											|it = 'iso-8859-1 (ISO dell''Europa occidentale)';
											|pl = 'iso-8859-1 (Europa Zachodnia ISO)';
											|tr = 'ISO-8859-1 (Batı Avrupa ISO)'"));
	EncodingsList.Add("iso-8859-2",   NStr("vi = 'ISO-8859-2 (ISO Trung Âu)';
											|ru = 'ISO-8859-2 (Центральноевропейская ISO)';
											|en = 'ISO-8859-2 (Central European ISO)'; fa = 'ISO-8859-2 (Central European ISO)';
											|it = 'iso-8859-2 (ISO dell''Europa centrale)';
											|pl = 'iso-8859-2 (Europa środkowa ISO)';
											|tr = 'ISO-8859-2 (Orta Avrupa ISO)'"));
	EncodingsList.Add("iso-8859-3",   NStr("vi = 'ISO-8859-3 (3 ISO Latin)';
											|ru = 'ISO-8859-3 (Латиница 3 ISO)';
											|en = 'ISO-8859-3 (Latin-3 ISO)'; fa = 'ISO-8859-3 (Latin-3 ISO)';
											|it = 'iso-8859-3 (Alfabeto latino 3 ISO)';
											|pl = 'iso-8859-3 (Łaciński 3 ISO)';
											|tr = 'ISO-8859-3 (Latin 3 ISO)'"));
	EncodingsList.Add("iso-8859-4",   NStr("vi = 'ISO-8859-4 (ISO Baltic)';
											|ru = 'ISO-8859-4 (Балтийская ISO)';
											|en = 'ISO-8859-4 (Baltic ISO)'; fa = 'ISO-8859-4 (Baltic ISO)';
											|it = 'iso-8859-4 (ISO del Baltico)';
											|pl = 'iso-8859-4 (Bałtycki ISO)';
											|tr = 'ISO-8859-4 (Baltik ISO)'"));
	EncodingsList.Add("iso-8859-5",   NStr("vi = 'ISO-8859-5 (ISO Cyrillic)';
											|ru = 'ISO-8859-5 (Кириллица ISO)';
											|en = 'ISO-8859-5 (Cyrillic ISO)'; fa = 'ISO-8859-5 (Cyrillic ISO)';
											|it = 'iso-8859-5 (Alfabeto cirillico ISO)';
											|pl = 'iso-8859-5 (Cyrylica ISO)';
											|tr = 'ISO-8859-5 (Kiril ISO)'"));
	EncodingsList.Add("iso-8859-7",   NStr("vi = 'ISO-8859-7 (ISO Hy Lạp)';
											|ru = 'ISO-8859-7 (Греческая ISO)';
											|en = 'ISO-8859-7 (Greek ISO)'; fa = 'ISO-8859-7 (Greek ISO)';
											|it = 'iso-8859-7 (ISO greca)';
											|pl = 'iso-8859-7 (Grecki ISO)';
											|tr = 'ISO-8859-7 (Yunan ISO)'"));
	EncodingsList.Add("iso-8859-9",   NStr("vi = 'ISO-8859-9 (ISO Thổ Nhĩ Kỳ)';
											|ru = 'ISO-8859-9 (Турецкая ISO)';
											|en = 'ISO-8859-9 (Turkish ISO)'; fa = 'ISO-8859-9 (Turkish ISO)';
											|it = 'iso-8859-9 (ISO turca)';
											|pl = 'iso-8859-9 (Turecki ISO)';
											|tr = 'ISO-8859-9 (Türkçe ISO)'"));
	EncodingsList.Add("iso-8859-15",  NStr("vi = 'ISO-8859-15 (9 ISO Latin)';
											|ru = 'ISO-8859-15 (Латиница 9 ISO)';
											|en = 'ISO-8859-15 (Latin-9 ISO)'; fa = 'ISO-8859-15 (Latin-9 ISO)';
											|it = 'iso-8859-15 (Alfabeto latino 9 ISO)';
											|pl = 'iso-8859-15 (Łaciński 9 ISO)';
											|tr = 'ISO-8859-15 (Latin 9 ISO)'"));
	EncodingsList.Add("koi8-r",       NStr("vi = 'KOI8-R (KOI8-R Cyrillic)';
											|ru = 'KOI8-R (Кириллица KOI8-R)';
											|en = 'KOI8-R (Cyrillic KOI8-R)'; fa = 'KOI8-R (Cyrillic KOI8-R)';
											|it = 'koi8-r (Alfabeto cirillico KOI8-R)';
											|pl = 'koi8-r (Cyrylica KOI8-R)';
											|tr = 'KOI8-R (Kiril KOI8-R)'"));
	EncodingsList.Add("koi8-u",       NStr("vi = 'KOI8-U (KOI8-U Cyrillic)';
											|ru = 'KOI8-U (Кириллица KOI8-U)';
											|en = 'KOI8-U (Cyrillic KOI8-U)'; fa = 'KOI8-U (Cyrillic KOI8-U)';
											|it = 'koi8-u (Alfabeto cirillico KOI8-U)';
											|pl = 'koi8-u (Cyrylica KOI8-U)';
											|tr = 'KOI8-U (Kiril KOI8-U)'"));
	EncodingsList.Add("us-ascii",     NStr("vi = 'US-ASCII (USA)';
											|ru = 'US-ASCII (США)';
											|en = 'US-ASCII (USA)'; fa = 'US-ASCII (USA)';
											|it = 'US-ASCII (USA)';
											|pl = 'US-ASCII (USA)';
											|tr = 'US-ASCII (ABD)'"));
	EncodingsList.Add("utf-8",        NStr("vi = 'UTF-8 (Unicode UTF-8)';
											|ru = 'UTF-8 (Юникод UTF-8)';
											|en = 'UTF-8 (Unicode UTF-8)'; fa = 'UTF-8 (Unicode UTF-8)';
											|it = 'utf-8 (Unicode UTF-8)';
											|pl = 'utf-8 (Unikod UTF-8)';
											|tr = 'UTF-8 (Unicode UTF-8)'"));
	EncodingsList.Add("utf-8_WithoutBOM", NStr("vi = 'UTF-8 (Unicode UTF-8 không có BOM)';
												|ru = 'UTF-8 (Юникод UTF-8 без BOM)';
												|en = 'UTF-8 (Unicode UTF-8 without BOM)'; fa = 'UTF-8 (Unicode UTF-8 without BOM)';
												|it = 'UTF-8 (Unicode UTF-8 senza BOM)';
												|pl = 'UTF-8 (Unicode UTF-8 bez BOM)';
												|tr = 'UTF-8 (Unicode UTF-8 ürün reçetesiz)'"));
	EncodingsList.Add("windows-1250", NStr("vi = 'Windows-1250 (Windows Trung Âu)';
											|ru = 'Windows-1250 (Центральноевропейская Windows)';
											|en = 'Windows-1250 (Central European Windows)'; fa = 'Windows-1250 (Central European Windows)';
											|it = 'wndows-1250 (Windows dell''Europa centrale)';
											|pl = 'Windows-1250 (Europa Środkowa Windows)';
											|tr = 'Windows-1250 (Orta Avrupa Windows)'"));
	EncodingsList.Add("windows-1251", NStr("vi = 'windows-1251 (Windows Cyrillic)';
											|ru = 'windows-1251 (Кириллица Windows)';
											|en = 'Windows-1251 (Cyrillic Windows)'; fa = 'Windows-1251 (Cyrillic Windows)';
											|it = 'windows-1251 (Alfabeto cirillico Windows)';
											|pl = 'windows-1251 (Cyrylica Windows)';
											|tr = 'Windows-1251 (Kiril Windows)'"));
	EncodingsList.Add("windows-1252", NStr("vi = 'Windows-1252 (Windows Tây Âu)';
											|ru = 'Windows-1252 (Западноевропейская Windows)';
											|en = 'Windows-1252 (Western European Windows)'; fa = 'Windows-1252 (Western European Windows)';
											|it = 'windows-1252 (Windows dell''Europa occidentale)';
											|pl = 'Windows-1252 (Europa Zachodnia Windows)';
											|tr = 'Windows-1252 (Batı Avrupa Windows)'"));
	EncodingsList.Add("windows-1253", NStr("vi = 'Windows-1253 (Windows Hy Lạp)';
											|ru = 'Windows-1253 (Греческая Windows)';
											|en = 'Windows-1253 (Greek Windows)'; fa = 'Windows-1253 (Greek Windows)';
											|it = 'windows-1253 (Windows greco)';
											|pl = 'Windows-1253 (Grecki Windows)';
											|tr = 'Windows-1253 (Yunan Windows)'"));
	EncodingsList.Add("windows-1254", NStr("vi = 'Windows-1254 (Windows Thổ Nhĩ Kỳ)';
											|ru = 'Windows-1254 (Турецкая Windows)';
											|en = 'Windows-1254 (Turkish Windows)'; fa = 'Windows-1254 (Turkish Windows)';
											|it = 'windows-1254 (Windows turco)';
											|pl = 'Windows-1254 (Turecki Windows)';
											|tr = 'Windows-1254 (Türkçe Windows)'"));
	EncodingsList.Add("windows-1257", NStr("vi = 'Windows-1257 (Windows Baltic)';
											|ru = 'Windows-1257 (Балтийская Windows)';
											|en = 'Windows-1257 (Baltic Windows)'; fa = 'Windows-1257 (Baltic Windows)';
											|it = 'windows-1257 (Windows baltico)';
											|pl = 'Windows-1257 (Bałtycki Windows)';
											|tr = 'Windows-1257 (Baltik Windows)'"));
	
	Return EncodingsList;

EndFunction

Function ScanningParameters() Export
	
	ScanningParameters = New Structure; 
	ScanningParameters.Insert("ShowDialogBox", True);
	ScanningParameters.Insert("SelectedDevice", "");
	ScanningParameters.Insert("PictureFormat", "png");
	ScanningParameters.Insert("Resolution", 200);
	ScanningParameters.Insert("Chromaticity", 1);
	ScanningParameters.Insert("Rotation", 0);
	ScanningParameters.Insert("PaperSize", 1);
	ScanningParameters.Insert("JPGQuality", 100);
	ScanningParameters.Insert("TIFFDeflation", 6);
	ScanningParameters.Insert("DuplexScanning", False);
	ScanningParameters.Insert("DocumentAutoFeeder", False);
	ScanningParameters.Insert("ShouldSaveAsPDF", False);
	ScanningParameters.Insert("UseImageMagickToConvertToPDF", False);
	Return ScanningParameters;
	
EndFunction

#EndRegion

#EndRegion