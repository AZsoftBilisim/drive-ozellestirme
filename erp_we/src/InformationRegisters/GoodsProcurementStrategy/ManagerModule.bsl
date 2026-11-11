#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Warehouse)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region Internal

// Parameters:
//   Table - ValueTable - the table to fill in.
//   SupplyMethod - CatalogRef.ProcurementStrategies - A way to meet your needs.
// Returns:
//   Array - identifiers of processed strings.
Function FillInCollateralMethod(Table, SupplyMethod) Export
	
	Set = InformationRegisters.GoodsProcurementStrategy.CreateRecordSet();
	ProcessedRows = New Array();
	
	If ValueIsFilled(SupplyMethod) Then
		
		Set.Add();
		Record = Set[0];
		Record.AddlOrderingAttribute = 1;
		Record.ProcurementStrategy = SupplyMethod;
		
		For Each TableRow In Table Do
			
			FillPropertyValues(Record, TableRow);
			Set.Filter.Products.Set(TableRow.Products);
			Set.Filter.Characteristic.Set(TableRow.Characteristic);
			Set.Filter.Warehouse.Set(TableRow.Warehouse);
			
			Try
				
				Set.Write();
				ProcessedRows.Add(TableRow.Id);
				
			Except
				
				ErrorComment = ErrorInfo();
				LogEventName = NStr("vi = 'Điền vào phương thức cung cấp hàng hóa';
									|ru = 'Заполнение способа обеспечения товаров';
									|en = 'Fill in goods procurement strategy'; fa = 'Fill in goods procurement strategy';
									|it = 'Compilazione del metodo di approvvigionamento delle merci';
									|pl = 'Wypełnianie sposobu zaspokajania towarów';
									|tr = 'Ürün tedarik yönteminin doldurulması'", CommonClientServer.DefaultLanguageCode());
				WriteLogEvent(LogEventName,
					EventLogLevel.Error,
					Metadata.InformationRegisters.GoodsProcurementStrategy,
					,
					ErrorComment);
				
			EndTry;
			
		EndDo;
		
	Else
		
		For Each TableRow In Table Do
			
			Set.Filter.Products.Set(TableRow.Products);
			Set.Filter.Characteristic.Set(TableRow.Characteristic);
			Set.Filter.Warehouse.Set(TableRow.Warehouse);
			
			Try
				
				Set.Write();
				ProcessedRows.Add(TableRow.Id);
				
			Except
				
				ErrorComment = ErrorInfo();
				LogEventName = NStr("vi = 'Điền vào phương thức cung cấp hàng hóa';
									|ru = 'Заполнение способа обеспечения товаров';
									|en = 'Fill in goods procurement strategy'; fa = 'Fill in goods procurement strategy';
									|it = 'Compilazione del metodo di approvvigionamento delle merci';
									|pl = 'Wypełnianie sposobu zaspokajania towarów';
									|tr = 'Ürün tedarik yönteminin doldurulması'", CommonClientServer.DefaultLanguageCode());
				WriteLogEvent(LogEventName,
					EventLogLevel.Error,
					Metadata.InformationRegisters.GoodsProcurementStrategy,
					,
					ErrorComment);
				
			EndTry;
			
		EndDo;
		
	EndIf;
	
	TextDataNotRecorded = NStr("vi = 'Không thể ghi lại các thay đổi đối với phương thức cung cấp hàng hóa.';
								|ru = 'Не удалось записать изменения способа обеспечения товарами.';
								|en = 'Cannot save changes of goods procurement strategy.'; fa = 'Cannot save changes of goods procurement strategy.';
								|it = 'Non è possibile salvare la modifica del metodo di approvvigionamento delle merci.';
								|pl = 'Nie można zapisać zmian w sposobie zabezpieczania towarów.';
								|tr = 'Ürün tedariki yöntemindeki değişiklikleri kaydetmek mümkün olmadı.'");
	TextDataIsWrittenPartially = NStr("vi = 'Đã ghi lại không phải tất cả các thay đổi trong phương thức cung cấp hàng hóa.';
										|ru = 'Не все изменения способа обеспечения товарами удалось записать.';
										|en = 'Cannot save all changes of goods procurement strategy.'; fa = 'Cannot save all changes of goods procurement strategy.';
										|it = 'Non è stato possibile salvare tutte le modifiche di approvvigionamento delle merci.';
										|pl = 'Nie wszystkie zmiany sposobu zabezpieczenia towarów zostały zapisane.';
										|tr = 'Ürün tedariki yöntemindeki tüm değişiklikler kaydedilmedi.'");
	ReportErrorsInRecordingParametersOfProvisionOfNeeds(
		Table,
		ProcessedRows,
		TextDataNotRecorded,
		TextDataIsWrittenPartially);
	
	Return ProcessedRows;
	
EndFunction

#EndRegion

Procedure ReportErrorsInRecordingParametersOfProvisionOfNeeds(Table, ProcessedRows, TextDataNotRecorded, TextDataIsWrittenPartially)
	
	TotalRowsInTable = Table.Count();
	TotalLinesRecorded = ProcessedRows.Count();
	If TotalRowsInTable > 0 And TotalLinesRecorded = 0 Then
		Message = New UserMessage();
		Message.Text = TextDataNotRecorded;
		Message.Message();
	ElsIf TotalRowsInTable > TotalLinesRecorded Then
		Message = New UserMessage();
		Message.Text = TextDataIsWrittenPartially;
		Message.Message();
	EndIf;
	
EndProcedure

#EndRegion

#EndIf