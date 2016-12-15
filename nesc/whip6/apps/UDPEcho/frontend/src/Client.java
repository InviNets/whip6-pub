/*
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2016 InviNets Sp z o.o.
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files. If you do not find these files, copies can be found by writing
 * to technology@invinets.com.
 */
import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.Inet6Address;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.net.UnknownHostException;
import java.util.Enumeration;



/**
 * A simple client for the UDPEcho application.
 * 
 * The command-line parameters are respectively:
 * - local IPv6 address
 * - local port number (optional, by default 9001)
 * - echo request timeout in milliseconds (optional, by default 5000)
 * 
 * @author Konrad Iwanicki
 */
public class Client {

	public static final int DEFAULT_PORT = 9001;
	public static final long DEFAULT_TIMEOUT = 5000;
	public static final int MAX_PACKET_SIZE = 2048;
	
	private static void printInfo() {
		System.out.println("whip6: Warsaw High-performance IPv6");
		System.out.println("Simple UDP over IPv6 client for the UDPEcho application");
		System.out.println("Copyright (C) 2013-2014, WhipTronics");
		System.out.println();
	}
	
	private static void printUsage() {
		System.err.println("Usage:");
		System.err.println("  java " + Client.class.getCanonicalName() +
				" <node_ipv6_addr> [<node_port> [<timeout_in_ms>]]");
		System.err.println();
	}
	
	private static class Receiver implements Runnable {
		private final DatagramSocket socket;
		public Receiver(DatagramSocket socketArg) {
			this.socket = socketArg;
		}
		public void run() {
			DatagramPacket rpacket = new DatagramPacket(new byte[MAX_PACKET_SIZE], MAX_PACKET_SIZE);
			while (true) {
				try {
					this.socket.receive(rpacket);
					String decoded = new String(rpacket.getData(), 0, rpacket.getLength(), "UTF-8");
					System.out.println("Received a " + rpacket.getLength() +
							"-byte packet: \"" + decoded + "\"!");
				} catch (IOException e) {
					System.err.println("ERROR: I/O exception: " + e.getMessage() + "!");
					System.err.println();
					printUsage();
					System.exit(1);
				}
			}
		}
	}

	private static Inet6Address getIPv6Address() throws SocketException {
		Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
	    while (interfaces.hasMoreElements()) {
	        NetworkInterface nic = interfaces.nextElement();
	        Enumeration<InetAddress> addresses = nic.getInetAddresses();
	        while (addresses.hasMoreElements()) {
	            InetAddress address = addresses.nextElement();
	            if (!address.isLoopbackAddress() && address instanceof Inet6Address) {
	                return (Inet6Address)address;
	            }
	        }
	    }
	    return null;
	}	
	
	/**
	 * The main method.
	 * @param args The program arguments.
	 */
	public static void main(String[] args) {
		printInfo();
		
		if (args.length < 1 || args.length > 3) {
			System.err.println("ERROR: Invalid arguments!");
			System.err.println();
			printUsage();
			System.exit(1);
		}
		
		long timeout = DEFAULT_TIMEOUT;
		if (args.length >= 3) {
			try {
				timeout = Long.parseLong(args[2]);
				if (timeout < DEFAULT_TIMEOUT) {
					throw new NumberFormatException();
				}
			} catch (NumberFormatException e) {
				System.err.println("ERROR: Invalid timeout \"" +
						args[2] + "\"! Must be at least " + DEFAULT_TIMEOUT + ".");
				System.err.println();
				printUsage();
				System.exit(1);
			}
		}
		
		int portNo = DEFAULT_PORT;
		if (args.length >= 2) {
			try {
				portNo = Integer.parseInt(args[1]);
				if (portNo < 1024 || portNo > 65535) {
					throw new NumberFormatException();
				}
			} catch (NumberFormatException e) {
				System.err.println("ERROR: Invalid port number \"" +
						args[1] + "\"!");
				System.err.println();
				printUsage();
				System.exit(1);
			}
		}
		
		Inet6Address addr = null;
		try {
			InetAddress addr4 = Inet6Address.getByName(args[0]);
			if (! (addr4 instanceof Inet6Address)) {
				throw new UnknownHostException();
			}
			addr = (Inet6Address)addr4;
		} catch (UnknownHostException e) {
			System.err.println("ERROR: Invalid IPv6 address \"" +
					args[0] + "\"!");
			System.err.println();
			printUsage();
			System.exit(1);
		}
		
		try {
			Inet6Address myAddr = getIPv6Address();
			if (myAddr == null) {
				System.err.println("ERROR: No IPv6 address!");
				System.err.println();
				printUsage();
				System.exit(1);
			}
			DatagramSocket socket = new DatagramSocket(0, myAddr);
			String myName = socket.getLocalAddress().getCanonicalHostName();
			byte[] myNameAsBytes = myName.getBytes("UTF-8");
			byte[] myNameAsBytesPlusZero = new byte[myNameAsBytes.length + 1];
			System.arraycopy(myNameAsBytes, 0, myNameAsBytesPlusZero, 0, myNameAsBytes.length);
			myNameAsBytesPlusZero[myNameAsBytesPlusZero.length - 1] = '\0';
			DatagramPacket spacket = new DatagramPacket(myNameAsBytesPlusZero, myNameAsBytesPlusZero.length);
			Thread th = new Thread(new Receiver(socket));
			th.setDaemon(true);
			th.start();
			while (true) {
				System.out.println("Sent a " + spacket.getLength() +
						"-byte packet: \"" + myName + "\" to " +
						" UDP port " + portNo + " of " + addr.toString() + "!");
				spacket.setAddress(addr);
				spacket.setPort(portNo);
				spacket.setData(myNameAsBytesPlusZero);
				spacket.setLength(myNameAsBytesPlusZero.length);
				socket.send(spacket);
				Thread.sleep(timeout);
			}
		} catch (SocketException e) {
			System.err.println("ERROR: Socket exception: " + e.getMessage() + "!");
			System.err.println();
			printUsage();
			System.exit(1);
		} catch (IOException e) {
			System.err.println("ERROR: I/O exception: " + e.getMessage() + "!");
			System.err.println();
			printUsage();
			System.exit(1);
		} catch (InterruptedException e) {
			System.err.println("ERROR: Interrupted exception: " + e.getMessage() + "!");
			System.err.println();
			printUsage();
			System.exit(1);
		}
	}

}
