import 'dart:convert';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'utils.dart';

class AuthApi {
  DbCollection store;
  String secret;
  AuthApi(this.store, this.secret);
  Router get router {
    final router = Router();
    router.post('/register', (Request req) async {
      final payload = await req.readAsString();
      final userInfo = json.decode(payload);
      final email = userInfo['email'];
      final password = userInfo['password'];

      // Todo Ensure email and password fields are presents
      if (email == null ||
          email.isEmpty ||
          password == null ||
          password.isEmpty) {
        return Response(HttpStatus.badRequest,
            body: 'Please provide your email and passowrd');
      }
      // Todo ensure user is unique
      final user = await store.findOne(where.eq('email', email));
      if (user != null) {
        return Response(HttpStatus.badRequest, body: "User already exit");
      }

      // Todo create user
      final salt = generateSalt();
      final hashedPassword = hashPassword(password, salt);

      await store.insertOne({
        'email': email,
        'password': hashedPassword,
        'salt': salt,
      });
      return Response.ok("Successfully registered user");
    });
    router.post('/login', (Request req) async {
      final payload = await req.readAsString();
      final userInfo = json.decode(payload);
      final email = userInfo['email'];
      final password = userInfo['password'];
      // Ensure email and passowrd fields are present
      if (email == null ||
          email.isEmpty ||
          password == null ||
          password.isEmpty) {
        return Response(HttpStatus.badRequest,
            body: 'Please provide your email and password');
      }
      final user = await store.findOne(where.eq('email', email));
      if (user == null) {
        return Response.forbidden('Incorrect user and/or password');
      }
      final hashedPassowrd = hashPassword(password, user['salt']);
      if (hashedPassowrd != user['password']) {
        return Response.forbidden('Incorrect user and/or password');
      }

      // Generate JWT and send with response
      final userId = (user['_id'] as ObjectId).toHexString();
      final token = geneerateJwt(userId, 'http://localhost', secret);
      return Response.ok(json.encode({'token': token}), headers: {
        HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
      });
    });
    router.post('/logout', (Request req) async {
      if (req.context['authDetails'] == null) {
        return Response.forbidden("Not authrizedto perform this operation");
      }
      return Response.ok("Successfully logged out");
    });
    return router;
  }
}
