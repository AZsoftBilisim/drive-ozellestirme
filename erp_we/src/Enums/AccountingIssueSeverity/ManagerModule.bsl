#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns a template for a text with a message about the problem for output to the closing of the month form, depending on the importance of the problem.
//	
// Parameters:
//	State - EnumRef.AccountingIssueSeverity - the importance of the problem affecting the explanatory text.
//	
// Returns:
//	String - template of a text with a message about the problem for output to the month closing form.
//
Function ProblemTextTemplateCodeExecutionError(State = Undefined) Export
	
	TextDependingOnState = New Map;
	TextDependingOnState.Insert(Enums.AccountingIssueSeverity.Warning,
		NStr("vi = 'Khi thực hiện tính toán kỳ %2 theo doanh nghiệp ""%1"" đã phát hiện thấy vấn đề';
			|ru = 'При выполнении расчета периода %2 по организации ""%1"" обнаружены проблемы';
			|en = 'Some issues occurred when calculating the %2 period for the %1 company'; fa = 'Some issues occurred when calculating the %2 period for the %1 company';
			|it = 'При выполнении расчета периода %2 по организации ""%1"" обнаружены проблемы';
			|pl = 'Some issues occurred when calculating the %2 period for the %1 company';
			|tr = '""""%1"" iş yerinin %2 dönemindeki rapor hesaplamasının gerçekleştirilmesinde sorunlar bulundu'", Common.DefaultLanguageCode()));
	
	DefaultText = NStr("vi = 'Khi thực hiện tính toán kỳ %2 theo doanh nghiệp ""%1"" đã xảy ra tình huống ngoại lệ';
						|ru = 'При выполнении расчета периода %2 по организации ""%1"" произошла исключительная ситуация';
						|en = 'An exception is thrown when calculating the %2 period for the ""%1"" company'; fa = 'An exception is thrown when calculating the %2 period for the ""%1"" company';
						|it = 'Durante il calcolo del periodo %2 per la società ""%1"" si è verificata una situazione eccezionale';
						|pl = 'Podczas wykonania rozliczenia okresu %2 dla firmy ""%1"" wystąpiła wyjątkowa sytuacja';
						|tr = '""%1"""" iş yerinin %2 dönemindeki rapor hesaplamasının gerçekleştirilmesinde istisnai bir sorun oluştu'", Common.DefaultLanguageCode());
	
	Text = TextDependingOnState.Get(State);
	Text = ?(Text = Undefined, DefaultText, Text);
	
	Return Text;
	
EndFunction

#EndRegion

#EndIf