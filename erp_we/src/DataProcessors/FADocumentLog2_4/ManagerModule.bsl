#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region Commands

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// 
// Returns:
//  String - The key purpose of the default form
Function DefaultFormAssignmentKey() Export
	
	Return "FADocuments";
	
EndFunction

// 
// Parameters:
//  Parameters - Structure - 
// 
// Returns:
//  FormattedString - The data of the workplace
Function WorkplaceData(Parameters) Export

	Hyperlink = Undefined;
	
	ListOfHyperlinks = New Array;
	
	If AccessRight("View", Metadata.DataProcessors.RecognizeAndIncludeExpensesInFixedAssetCost) Then
		
		HyperlinkText = HyperLinkAcceptanceForAccounting(Parameters);
		ListOfHyperlinks.Add(" ");
		ListOfHyperlinks.Add(HyperlinkText);
	
	EndIf;
	
	
	If AccessRight("View", Metadata.DataProcessors.CorrectAccountingErrors) Then
		HyperlinkText = HyperlinkCorrectionOfErrorsInFAAccounting(Parameters);
		ListOfHyperlinks.Add(" ");
		ListOfHyperlinks.Add(HyperlinkText);
	EndIf;
		
	If ListOfHyperlinks.Count() <> 0 Then
		ListOfHyperlinks.Insert(0, NStr("vi = 'Cần lập:';
										|ru = 'К оформлению:';
										|en = 'To register:'; fa = 'To register:';
										|it = 'К оформлению:';
										|pl = 'Do sporządzenia:';
										|tr = 'Düzenlenecek:'"));
		Hyperlink = New FormattedString(ListOfHyperlinks);
	EndIf;
	
	Return Hyperlink;
	
EndFunction

Function HyperLinkAcceptanceForAccounting(Parameters)

	HasData = DataProcessors.RecognizeAndIncludeExpensesInFixedAssetCost.HasData(
		BegOfMonth(CurrentSessionDate()), 
		EndOfMonth(CurrentSessionDate()),
		Parameters.Organization);
	
	HyperlinkText = NStr("vi = 'Tiếp nhận vào kế toán';
						|ru = 'Принятие к учету';
						|en = 'Recognition'; fa = 'شناسایی';
						|it = 'Presa in considerazione';
						|pl = 'Przyjęcie do ewidencji';
						|tr = 'Muhasebeleştirme'");
	If HasData Then
		ColorOfHyperlink = Undefined;
	Else
		ColorOfHyperlink = StyleColors.EmptyTableField;
	EndIf;
	
	Hyperlink = New FormattedString(HyperlinkText,, ColorOfHyperlink,, "#FixedAssetsInitialRecognition");
	
	Return Hyperlink;
	
EndFunction

Function HyperlinkCorrectionOfErrorsInFAAccounting(Parameters)

	HyperlinkText = NStr("vi = 'Sửa lỗi khi ghi nhận';
						|ru = 'Исправление ошибок в учете';
						|en = 'Correct accounting errors'; fa = 'اصلاح خطاهای حسابداری';
						|it = 'Исправление ошибок в учете';
						|pl = 'Correct accounting errors';
						|tr = 'Muhasebe hatalarını düzelt'");
	ColorOfHyperlink = Undefined;
	
	Hyperlink = New FormattedString(HyperlinkText,, ColorOfHyperlink,, "#CorrectAccountingErrors");
	
	Return Hyperlink;
	
EndFunction


#EndRegion

#EndIf
