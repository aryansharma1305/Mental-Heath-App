import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:supabase/supabase.dart';

late SupabaseClient supabase;

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/api/health', _healthCheckHandler)
  
  // Users
  ..get('/api/users', _getUsersHandler)
  ..get('/api/users/<id>', _getUserByIdHandler)
  ..post('/api/users', _postUsersHandler)
  ..put('/api/users/<id>', _putUsersHandler)

  // Questions
  ..get('/api/questions', _getQuestionsHandler)
  ..post('/api/questions', _postQuestionsHandler)
  ..put('/api/questions/<id>', _putQuestionsHandler)
  ..delete('/api/questions/<id>', _deleteQuestionsHandler)

  // Templates
  ..get('/api/templates', _getTemplatesHandler)
  ..get('/api/templates/<id>', _getTemplateByIdHandler)
  ..post('/api/templates', _postTemplatesHandler)
  ..put('/api/templates/<id>', _putTemplatesHandler)
  ..delete('/api/templates/<id>', _deleteTemplatesHandler)

  // Template Questions
  ..post('/api/templates/<id>/questions', _postTemplateQuestionsHandler)
  ..delete('/api/templates/<id>/questions/<qid>', _deleteTemplateQuestionsHandler)
  ..put('/api/templates/<id>/questions/order', _putTemplateQuestionsOrderHandler)

  // Question Responses
  ..get('/api/question_responses', _getQuestionResponsesHandler)
  ..post('/api/question_responses', _postQuestionResponsesHandler)

  // Assessments
  ..post('/api/assessments', _postAssessmentsHandler)
  ..get('/api/assessments', _getAssessmentsHandler)
  ..put('/api/assessments/<id>', _putAssessmentsHandler)

  // Patients
  ..post('/api/patients', _postPatientsHandler)
  ..get('/api/patients', _getPatientsHandler);

Response _rootHandler(Request req) => Response.ok('Mental Capacity Assessment API\n');

Response _healthCheckHandler(Request req) => _jsonResponse({'status': 'ok'});

// ========== HELPERS ==========

Response _jsonResponse(dynamic data, {int statusCode = 200}) {
  return Response(statusCode, body: jsonEncode(data), headers: {'content-type': 'application/json'});
}

Response _errorResponse(dynamic e, {int statusCode = 500}) {
  print('API Error: $e');
  return Response(statusCode, body: jsonEncode({'error': e.toString()}), headers: {'content-type': 'application/json'});
}

// ========== USERS ==========

Future<Response> _getUsersHandler(Request req) async {
  try {
    final username = req.url.queryParameters['username'];
    if (username != null) {
      final response = await supabase.from('users').select().eq('username', username).maybeSingle();
      if (response == null) return Response.notFound(jsonEncode({'error': 'User not found'}));
      return _jsonResponse(response);
    }
    final response = await supabase.from('users').select();
    return _jsonResponse(response);
  } catch (e) {
    return _errorResponse(e);
  }
}

Future<Response> _getUserByIdHandler(Request req, String id) async {
  try {
    final response = await supabase.from('users').select().eq('id', id).maybeSingle();
    if (response == null) return Response.notFound(jsonEncode({'error': 'User not found'}));
    return _jsonResponse(response);
  } catch (e) {
    return _errorResponse(e);
  }
}

Future<Response> _postUsersHandler(Request req) async {
  try {
    final data = jsonDecode(await req.readAsString());
    final response = await supabase.from('users').insert(data).select().single();
    return _jsonResponse(response, statusCode: 201);
  } catch (e) {
    return _errorResponse(e);
  }
}

Future<Response> _putUsersHandler(Request req, String id) async {
  try {
    final data = jsonDecode(await req.readAsString());
    final response = await supabase.from('users').update(data).eq('id', id).select().single();
    return _jsonResponse(response);
  } catch (e) {
    return _errorResponse(e);
  }
}

// ========== QUESTIONS ==========

Future<Response> _getQuestionsHandler(Request req) async {
  try {
    final activeOnly = req.url.queryParameters['active'] == 'true';
    var query = supabase.from('questions').select();
    if (activeOnly) query = query.eq('is_active', true);
    final response = await query.order('order_index', ascending: true);
    return _jsonResponse(response);
  } catch (e) {
    return _errorResponse(e);
  }
}

Future<Response> _postQuestionsHandler(Request req) async {
  try {
    final data = jsonDecode(await req.readAsString());
    final response = await supabase.from('questions').insert(data).select().single();
    return _jsonResponse(response, statusCode: 201);
  } catch (e) {
    return _errorResponse(e);
  }
}

Future<Response> _putQuestionsHandler(Request req, String id) async {
  try {
    final data = jsonDecode(await req.readAsString());
    final response = await supabase.from('questions').update(data).eq('id', id).select().single();
    return _jsonResponse(response);
  } catch (e) {
    return _errorResponse(e);
  }
}

Future<Response> _deleteQuestionsHandler(Request req, String id) async {
  try {
    await supabase.from('questions').update({'is_active': false}).eq('id', id);
    return _jsonResponse({'success': true});
  } catch (e) {
    return _errorResponse(e);
  }
}

// ========== TEMPLATES ==========

Future<Response> _getTemplatesHandler(Request req) async {
  try {
    final response = await supabase.from('assessment_templates').select().eq('is_active', true).order('created_at', ascending: false);
    return _jsonResponse(response);
  } catch (e) {
    return _errorResponse(e);
  }
}

Future<Response> _getTemplateByIdHandler(Request req, String id) async {
  try {
    final templateResponse = await supabase.from('assessment_templates').select().eq('id', id).maybeSingle();
    if (templateResponse == null) return Response.notFound(jsonEncode({'error': 'Template not found'}));

    final questionsResponse = await supabase.from('assessment_template_questions')
        .select('question_id, order_index, questions (*)')
        .eq('template_id', id)
        .order('order_index', ascending: true);

    final questions = questionsResponse.map((item) => item['questions']).where((q) => q != null).toList();
    
    return _jsonResponse({...templateResponse, 'questions': questions});
  } catch (e) {
    return _errorResponse(e);
  }
}

Future<Response> _postTemplatesHandler(Request req) async {
  try {
    final data = jsonDecode(await req.readAsString());
    final response = await supabase.from('assessment_templates').insert(data).select().single();
    return _jsonResponse(response, statusCode: 201);
  } catch (e) {
    return _errorResponse(e);
  }
}

Future<Response> _putTemplatesHandler(Request req, String id) async {
  try {
    final data = jsonDecode(await req.readAsString());
    final response = await supabase.from('assessment_templates').update(data).eq('id', id).select().single();
    return _jsonResponse(response);
  } catch (e) {
    return _errorResponse(e);
  }
}

Future<Response> _deleteTemplatesHandler(Request req, String id) async {
  try {
    await supabase.from('assessment_templates').update({'is_active': false}).eq('id', id);
    return _jsonResponse({'success': true});
  } catch (e) {
    return _errorResponse(e);
  }
}

Future<Response> _postTemplateQuestionsHandler(Request req, String id) async {
  try {
    final data = jsonDecode(await req.readAsString());
    await supabase.from('assessment_template_questions').insert({
      'template_id': id,
      'question_id': data['question_id'],
      'order_index': data['order_index'],
    });
    return _jsonResponse({'success': true}, statusCode: 201);
  } catch (e) {
    return _errorResponse(e);
  }
}

Future<Response> _deleteTemplateQuestionsHandler(Request req, String id, String qid) async {
  try {
    await supabase.from('assessment_template_questions').delete().eq('template_id', id).eq('question_id', qid);
    return _jsonResponse({'success': true});
  } catch (e) {
    return _errorResponse(e);
  }
}

Future<Response> _putTemplateQuestionsOrderHandler(Request req, String id) async {
  try {
    final data = jsonDecode(await req.readAsString());
    final List<dynamic> questionIds = data['question_ids'];
    
    await supabase.from('assessment_template_questions').delete().eq('template_id', id);
    for (int i = 0; i < questionIds.length; i++) {
      await supabase.from('assessment_template_questions').insert({
        'template_id': id,
        'question_id': questionIds[i],
        'order_index': i,
      });
    }
    return _jsonResponse({'success': true});
  } catch (e) {
    return _errorResponse(e);
  }
}

// ========== QUESTION RESPONSES ==========

Future<Response> _getQuestionResponsesHandler(Request req) async {
  try {
    var query = supabase.from('question_responses').select('*, questions(*), assessment_templates(name, description)');
    final templateId = req.url.queryParameters['template_id'];
    final patientUserId = req.url.queryParameters['patient_user_id'];
    final assessmentId = req.url.queryParameters['assessment_id'];
    
    if (templateId != null) query = query.eq('template_id', templateId);
    if (patientUserId != null) query = query.eq('patient_user_id', patientUserId);
    if (assessmentId != null) query = query.eq('assessment_id', assessmentId);
    
    final response = await query.order('created_at', ascending: false);
    return _jsonResponse(response);
  } catch (e) {
    return _errorResponse(e);
  }
}

Future<Response> _postQuestionResponsesHandler(Request req) async {
  try {
    final data = jsonDecode(await req.readAsString());
    final response = await supabase.from('question_responses').insert(data).select().single();
    return _jsonResponse(response, statusCode: 201);
  } catch (e) {
    return _errorResponse(e);
  }
}

// ========== ASSESSMENTS ==========

Future<Response> _postAssessmentsHandler(Request req) async {
  try {
    final data = jsonDecode(await req.readAsString());
    final response = await supabase.from('assessments').insert(data).select().single();
    return _jsonResponse(response, statusCode: 201);
  } catch (e) {
    return _errorResponse(e);
  }
}

Future<Response> _putAssessmentsHandler(Request req, String id) async {
  try {
    final data = jsonDecode(await req.readAsString());
    final response = await supabase.from('assessments').update(data).eq('id', id).select().single();
    return _jsonResponse(response);
  } catch (e) {
    return _errorResponse(e);
  }
}

Future<Response> _getAssessmentsHandler(Request req) async {
  try {
    var query = supabase.from('assessments').select();
    
    final status = req.url.queryParameters['status'];
    if (status != null) query = query.eq('status', status);
    
    final review = req.url.queryParameters['review'];
    if (review == 'true') query = query.inFilter('status', ['pending', 'reviewed']);
    
    final patientUserId = req.url.queryParameters['patient_user_id'];
    if (patientUserId != null) query = query.eq('patient_user_id', patientUserId);
    
    final assessorUserId = req.url.queryParameters['assessor_user_id'];
    if (assessorUserId != null) query = query.eq('assessor_user_id', assessorUserId);
    
    final unassigned = req.url.queryParameters['unassigned'];
    if (unassigned == 'true') query = query.or('assessor_user_id.is.null,assessor_user_id.eq.');
    
    final response = await query.order('assessment_date', ascending: false);
    return _jsonResponse(response);
  } catch (e) {
    return _errorResponse(e);
  }
}

// ========== PATIENTS ==========

Future<Response> _postPatientsHandler(Request req) async {
  try {
    final data = jsonDecode(await req.readAsString());
    final response = await supabase.from('patients').upsert(data).select().single();
    return _jsonResponse(response, statusCode: 201);
  } catch (e) {
    return _errorResponse(e);
  }
}

Future<Response> _getPatientsHandler(Request req) async {
  try {
    final response = await supabase.from('patients').select().order('last_assessment_at', ascending: false);
    return _jsonResponse(response);
  } catch (e) {
    return _errorResponse(e);
  }
}

void main(List<String> args) async {
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final supabaseUrl = env['SUPABASE_URL'] ?? 'https://uikkanfplfjglehpfrwu.supabase.co';
  final supabaseKey = env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVpa2thbmZwbGZqZ2xlaHBmcnd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU5ODQ1NDksImV4cCI6MjA4MTU2MDU0OX0.SCtZgXvtFfla5rvadCxHi2OLbLADNduiYA-Qu3Dav1M';

  supabase = SupabaseClient(supabaseUrl, supabaseKey);

  final ip = InternetAddress.anyIPv4;
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router.call);
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
