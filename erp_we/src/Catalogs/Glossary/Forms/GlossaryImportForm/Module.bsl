
#Region FormCommandsEventHandlers

&AtClient
Procedure DownloadGlossary(Command)
	
	ClearMessages();
	
	ImportResult1 = ResultOfDownloadOnServer();
	
	NotificationText1 = NStr("vi = 'Kết nhập các bảng chú giải';
							|ru = 'Загрузка глоссариев';
							|en = 'Import glossaries'; fa = 'Import glossaries';
							|it = 'Загрузка глоссариев';
							|pl = 'Import glossaries';
							|tr = 'Terim sözlüklerinin yüklenmesi'"); 
	
	If ImportResult1.Imported2 = 0 Then
		
		ExplanationText = NStr("vi = 'Chưa tải bảng thuật ngữ nào';
								|ru = 'Ни один глоссарий не загружен';
								|en = 'No glossary is imported'; fa = 'No glossary is imported';
								|it = 'Ни один глоссарий не загружен';
								|pl = 'No glossary is imported';
								|tr = 'Herhangi bir terim sözlüğü yüklenmedi'");
		
	Else
		
		ExplanationText = StrTemplate(NStr("vi = 'Đã kết nhập bảng thuật ngữ %1 trong số %2';
											|ru = 'Загружено глоссариев %1 из %2';
											|en = 'Imported %1 out of %2 glossaries'; fa = 'Imported %1 out of %2 glossaries';
											|it = 'Загружено глоссариев %1 из %2';
											|pl = 'Imported %1 out of %2 glossaries';
											|tr = '%2 üzerinden %1 terim sözlüğü yüklendi'"), ImportResult1.Imported2, ImportResult1.TotalToDownload);
		
	EndIf;
	
	ShowUserNotification(NotificationText1, , ExplanationText, PictureLib.Information32);
	
	For Each ErrorText In ImportResult1.Errors Do
		
		CommonClient.MessageToUser(ErrorText);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ResultOfDownloadOnServer()
	
	Result = New Structure;
	Result.Insert("Success",       True);
	Result.Insert("Errors",         New Array);
	Result.Insert("Imported2",      0);
	Result.Insert("TotalToDownload", 0);
	
	ResultOfFormation = ResultOfGeneratingTableOfValuesFromTableDocument(SpreadsheetDocument);
	If ResultOfFormation.ValueTable = Undefined Then 
		
		Result.Errors.Add(ResultOfFormation.ErrorText);
		Result.Success = False; 
		
		Return Result;
	EndIf;
	
	DataTable = ResultOfFormation.ValueTable; 
	
	If DataTable.Columns.Find("Description") = Undefined Then
		
		ErrorText = NStr("vi = 'Trong bảng dữ liệu chưa tìm thấy cột ""Tên gọi""';
						|ru = 'В таблице данных не найдена колонка ""Наименование""';
						|en = 'The ""Name"" column is not found in the data table'; fa = 'The ""Name"" column is not found in the data table';
						|it = 'В таблице данных не найдена колонка ""Наименование""';
						|pl = 'The ""Name"" column is not found in the data table';
						|tr = 'Veri tablosunda ""Tanım"" sütunu bulunamadı'");
		Result.Errors.Add(ErrorText);
		Result.Success = False;
		
	ElsIf Not ValueIsFilled(DataTable.Columns.Description.ValueType) Then
		
		ErrorText = NStr("vi = 'Chưa chỉ định giá trị nào vào cột ""Tên gọi""';
						|ru = 'Не указано ни одно значение в колонке ""Наименование""';
						|en = 'No value is specified in the ""Description"" column'; fa = 'No value is specified in the ""Description"" column';
						|it = 'Не указано ни одно значение в колонке ""Наименование""';
						|pl = 'No value is specified in the ""Description"" column';
						|tr = '“Ad” sütununda hiçbir değer belirtilmemiştir'");
		Result.Errors.Add(ErrorText);
		Result.Success = False; 
		
		Return Result;
			
	EndIf;
	
	If DataTable.Columns.Find("LongDesc") = Undefined Then
		
		ErrorText = NStr("vi = 'Trong bảng dữ liệu chưa tìm thấy cột ""Tên gọi""';
						|ru = 'В таблице данных не найдена колонка ""Описание""';
						|en = 'The ""Details"" column is not found in the data table'; fa = 'The ""Details"" column is not found in the data table';
						|it = 'В таблице данных не найдена колонка ""Описание""';
						|pl = 'The ""Details"" column is not found in the data table';
						|tr = 'Veri tablosunda ""Ayrıntılar"" sütunu bulunamadı'");
		Result.Errors.Add(ErrorText);
		Result.Success = False;
		
	ElsIf Not ValueIsFilled(DataTable.Columns.LongDesc.ValueType) Then
		
		ErrorText = NStr("vi = 'Chưa chỉ định giá trị nào vào cột ""Mô tả""';
						|ru = 'Не указано ни одно значение в колонке ""Описание""';
						|en = 'No value is specified in the ""Details"" column'; fa = 'No value is specified in the ""Details"" column';
						|it = 'Не указано ни одно значение в колонке ""Описание""';
						|pl = 'No value is specified in the ""Details"" column';
						|tr = '“Açıklama” sütununda hiçbir değer belirtilmemiştir'");
		Result.Errors.Add(ErrorText);
		Result.Success = False; 
		
		Return Result;
		
	EndIf;
	
	If Not Result.Success Then
		Return Result;
	EndIf;
	
	CodeCurrentLanguage =  CurrentLanguage().LanguageCode;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	DataTable.Description AS Description,
		|	DataTable.LongDesc     AS LongDesc
		|INTO DataTable
		|FROM
		|	&DataTable AS DataTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataTable.Description                           AS Description,
		|	DataTable.LongDesc                               AS LongDesc,
		|	Glossary.Ref AS Ref
		|FROM
		|	DataTable AS DataTable
		|		LEFT JOIN Catalog.Glossary AS Glossary
		|		ON DataTable.Description = Glossary.Description";
	
	Query.SetParameter("DataTable", DataTable);
	
	SelectionDetailRecords = Query.Execute().Select();
	
	While SelectionDetailRecords.Next() Do
		
		Result.TotalToDownload = Result.TotalToDownload + 1;
		
		BeginTransaction();
		
		Try
		
			If ValueIsFilled(SelectionDetailRecords.Ref) Then
				
				If ReFillExistingOnes Then
					
						Block = New DataLock;
						LockItem = Block.Add(SelectionDetailRecords.Ref.Metadata().FullName());
						LockItem.SetValue("Ref", SelectionDetailRecords.Ref);
						Block.Lock();
						
						ObjectGlossary = SelectionDetailRecords.Ref.GetObject();
						
				Else
					Continue;
				EndIf;
				
			Else
				ObjectGlossary = Catalogs.Glossary.CreateItem();
			EndIf;
				
			ObjectGlossary.Description = SelectionDetailRecords.Description;
			DocumentDetailsList1 = New FormattedDocument;
			DocumentDetailsList1.Add(SelectionDetailRecords.LongDesc);
			
			NewRow = ObjectGlossary.GlossaryDetails.Add();
			NewRow.LanguageCode = CodeCurrentLanguage;
			NewRow.LongDesc = New ValueStorage(DocumentDetailsList1);
			
			ObjectGlossary.Write();
			Result.Imported2 = Result.Imported2 + 1;
			
			CommitTransaction();
		
		Except
			
			RollbackTransaction();
			
			ErrorText = StrTemplate(NStr("vi = 'Không thể ghi lại bảng thuật ngữ có tên gọi ""%1"" theo nguyên nhân -  %2';
										|ru = 'Не удалось записать глоссарий с наименованием ""%1"" по причине -  %2';
										|en = 'Cannot save the %1 glossary due to: %2'; fa = 'Cannot save the %1 glossary due to: %2';
										|it = 'Не удалось записать глоссарий с наименованием ""%1"" по причине -  %2';
										|pl = 'Cannot save the %1 glossary due to: %2';
										|tr = '""%1"" tanımlı terim sözlüğünün kaydedilememe nedeni;  %2'"),
			                        SelectionDetailRecords.Ref, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			Result.Errors.Add(ErrorText);
		
		EndTry;
		
	EndDo; 
	
	Return Result;
		
EndFunction

// Generates a table of values from a table document
// 
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument - from which the table of values is obtained
// 
// Returns:
//  Structure - The Result Of Generating A Table Of Values From A Table Document:
// * ValueTable - Undefined, ValueTable - generated table of values.
// * ErrorText     - String - error text if the Operation failed.
//
&AtServer
Function ResultOfGeneratingTableOfValuesFromTableDocument(SpreadsheetDocument) 
	
	Result = New Structure;
	Result.Insert("ValueTable", Undefined);
	Result.Insert("ErrorText",     "");
	
	LastRow = SpreadsheetDocument.TableHeight;
	LastColumn = SpreadsheetDocument.TableWidth;
	
	If LastColumn = 0 
		Or LastRow = 0 Then
		
		Result.ErrorText = NStr("vi = 'Chưa nhập dữ liệu đã kết nhập vào bảng';
								|ru = 'В таблице не введены загружаемые данные';
								|en = 'The data to import is not entered in the table'; fa = 'The data to import is not entered in the table';
								|it = 'В таблице не введены загружаемые данные';
								|pl = 'The data to import is not entered in the table';
								|tr = 'Tablo yüklenecek veriyi içermiyor'");
		Return Result;
		
	EndIf;
	CellArea = SpreadsheetDocument.Area(1, 1, LastRow, LastColumn);
	
	Try
	
		DataSource = New DataSourceDescription(CellArea);
		// Create an object for the intelligent construction of reports,
		// specify the data source and perform the construction of the report.
		ReportBuilder = New ReportBuilder;
		ReportBuilder.DataSource = DataSource;
		ReportBuilder.Execute();
		// The result is uploaded to the table of values.
		Result.ValueTable = ReportBuilder.Result.Unload();
	
	Except
		
		Result.ErrorText = NStr("vi = 'Đã chỉ định sai dữ liệu trong bảng. Trong dòng đầu tiên bắt đầu từ cột đầu tiên, cần chỉ định tên cột của bảng.
		                                   |Tiếp theo, từ dòng thứ hai là dữ liệu được kết nhập.';
		                                   |ru = 'Данные в таблице указаны неверно. В первой строке, начиная с первой колонки, должны быть указаны имена колонок таблицы.
		                                   |Далее, со второй строки, загружаемые данные.';
		                                   |en = 'The data in the table is incorrect. In the first row, starting from the first column, specify table column names.
		                                   |Next, starting from the second row, specify data to import.'; fa = 'The data in the table is incorrect. In the first row, starting from the first column, specify table column names.
		                                   |Next, starting from the second row, specify data to import.';
		                                   |it = 'Данные в таблице указаны неверно. В первой строке, начиная с первой колонки, должны быть указаны имена колонок таблицы.
		                                   |Далее, со второй строки, загружаемые данные.';
		                                   |pl = 'The data in the table is incorrect. In the first row, starting from the first column, specify table column names.
		                                   |Next, starting from the second row, specify data to import.';
		                                   |tr = 'Tablodaki veriler yanlış belirtilmiştir. İlk satırda, ilk sütundan başlayarak tablo sütunlarının adları belirtilmelidir.
		                                   |Ve ardından, ikinci satırdan itibaren yüklenecek veriler.'");
		Return Result;
		
	EndTry;
	
	Return Result;
	
EndFunction

#EndRegion



