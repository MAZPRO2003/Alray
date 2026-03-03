import React, { useEffect, useState, useRef } from 'react';
import { motion, AnimatePresence, useInView } from 'framer-motion';
import {
  Building2,
  Hammer,
  Layout,
  Map as MapIcon,
  ClipboardList,
  ShieldCheck,
  MapPin,
  Phone,
  Mail,
  MessageCircle,
  ArrowRight,
  ChevronDown,
  Menu,
  X,
  Coffee,
  PenTool,
  Truck,
  CheckCircle2
} from 'lucide-react';
import Lenis from 'lenis';
import { db } from './firebase';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import emailjs from '@emailjs/browser';
import Logo from './components/Logo';

// Animated Counter Component
const Counter = ({ value, title, suffix = "" }) => {
  const [count, setCount] = useState(0);
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true });

  useEffect(() => {
    if (isInView) {
      let start = 0;
      const end = parseInt(value);
      const duration = 2000;
      let startTimestamp = null;

      const step = (timestamp) => {
        if (!startTimestamp) startTimestamp = timestamp;
        const progress = Math.min((timestamp - startTimestamp) / duration, 1);
        setCount(Math.floor(progress * (end - start) + start));
        if (progress < 1) {
          window.requestAnimationFrame(step);
        }
      };
      window.requestAnimationFrame(step);
    }
  }, [isInView, value]);

  return (
    <div className="stat-box" ref={ref}>
      <h3 className="stat-number">{count}{suffix}</h3>
      <p>{title}</p>
    </div>
  );
};


function App() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [formLoading, setFormLoading] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    service: '',
    message: ''
  });
  const [formSubmitted, setFormSubmitted] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();

    // Validation
    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    const phoneRegex = /^[6-9]\d{9}$/;
    const cleanPhone = formData.phone.replace(/[^0-9]/g, '');

    if (!emailRegex.test(formData.email)) {
      alert("Please enter a valid email address.");
      return;
    }

    if (formData.phone && !phoneRegex.test(cleanPhone)) {
      alert("Please enter a valid 10-digit Indian mobile number.");
      return;
    }

    setFormLoading(true);
    try {
      // 1. Save inquiry to its own collection (separate from app contacts)
      await addDoc(collection(db, 'inquiries'), {
        name: formData.name,
        email: formData.email,
        phone: cleanPhone || formData.phone,
        service: formData.service,
        message: formData.message,
        createdAt: new Date(),
        status: 'new'
      });

      // 2. Send Email Notification via EmailJS
      // Note: User needs to provide Public Key, Service ID, and Template ID
      // Using placeholders - if these aren't set up, it will log an error but Firestore still works.
      try {
        const templateParams = {
          from_name: formData.name,
          from_email: formData.email,
          phone: formData.phone,
          service: formData.service,
          message: formData.message,
          to_email: 'alrayassociates@gmail.com'
        };

        // You can get these IDs from your EmailJS dashboard
        const EMAILJS_SERVICE_ID = 'service_alray';
        const EMAILJS_TEMPLATE_ID = 'template_inquiry';
        const EMAILJS_PUBLIC_KEY = 'YOUR_KEY_HERE';

        if (EMAILJS_PUBLIC_KEY !== 'YOUR_KEY_HERE') {
          await emailjs.send(
            EMAILJS_SERVICE_ID,
            EMAILJS_TEMPLATE_ID,
            templateParams,
            EMAILJS_PUBLIC_KEY
          );
        }
      } catch (emailErr) {
        console.warn("Email notification failed:", emailErr);
      }

      setFormSubmitted(true);
      setFormData({ name: '', email: '', phone: '', service: '', message: '' });
    } catch (error) {
      console.error("Error sending inquiry:", error);
      alert(`Failed to send inquiry: ${error.message}. Please try again.`);
    } finally {
      setFormLoading(false);
    }
  };

  useEffect(() => {
    const lenis = new Lenis({
      duration: 1.2,
      easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
      smoothWheel: true,
    });

    function raf(time) {
      lenis.raf(time);
      requestAnimationFrame(raf);
    }

    requestAnimationFrame(raf);

    const handleScroll = () => {
      setIsScrolled(window.scrollY > 50);
    };

    window.addEventListener('scroll', handleScroll);
    return () => {
      window.removeEventListener('scroll', handleScroll);
      lenis.destroy();
    };
  }, []);

  const fadeIn = {
    initial: { opacity: 0, y: 20 },
    whileInView: { opacity: 1, y: 0 },
    viewport: { once: true },
    transition: { duration: 0.8, ease: "easeOut" }
  };

  const navLinks = [
    { name: 'About Us', href: '#welcome' },
    { name: 'Services', href: '#services' },
    { name: 'Projects', href: '#projects' },
    { name: 'Our Process', href: '#process' },
  ];

  return (
    <div className="app-container">
      {/* Floating WhatsApp Button */}
      <a
        href="https://wa.me/918667011700"
        target="_blank"
        rel="noopener noreferrer"
        className="whatsapp-btn"
      >
        <div className="whatsapp-pulse"></div>
        <MessageCircle size={32} />
      </a>

      {/* Mobile Menu Backdrop */}
      <AnimatePresence>
        {mobileMenuOpen && (
          <motion.div
            className="mobile-backdrop"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setMobileMenuOpen(false)}
            style={{
              position: 'fixed',
              top: 0,
              left: 0,
              width: '100%',
              height: '100%',
              background: 'rgba(0,0,0,0.6)',
              zIndex: 1000,
              backdropFilter: 'blur(4px)'
            }}
          />
        )}
      </AnimatePresence>

      {/* Navigation */}
      <nav className={`navbar ${isScrolled || mobileMenuOpen ? 'scrolled' : ''}`}>
        <div className="container nav-content">
          <div className="logo">
            <a href="#home">
              <Logo light={!isScrolled && !mobileMenuOpen} />
            </a>
          </div>

          <ul className={`nav-links ${mobileMenuOpen ? 'active' : ''}`}>
            {mobileMenuOpen && (
              <li className="mobile-menu-header">
                <Logo />
                <button onClick={() => setMobileMenuOpen(false)} className="close-menu"><X /></button>
              </li>
            )}
            {navLinks.map((link) => (
              <li key={link.name}>
                <a
                  href={link.href}
                  onClick={() => setMobileMenuOpen(false)}
                >
                  {link.name}
                </a>
              </li>
            ))}
            <li>
              <a
                href="#contact"
                className="btn btn-primary"
                onClick={() => setMobileMenuOpen(false)}
              >
                Contact Us
              </a>
            </li>
          </ul>

          <div className="menu-toggle" onClick={() => setMobileMenuOpen(!mobileMenuOpen)}>
            {mobileMenuOpen ? <X size={28} /> : <Menu size={28} />}
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <header id="home" className="hero">
        <motion.div
          className="hero-bg"
          initial={{ scale: 1.1 }}
          animate={{ scale: 1 }}
          transition={{ duration: 10, repeat: Infinity, repeatType: "reverse" }}
        />
        <div className="container hero-content">
          <motion.div
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 1, ease: "easeOut" }}
          >
            <h1 className="gradient-text">Building Your Dreams Into Reality</h1>
            <p>
              World-class infrastructure and Real Estate Development committed to total
              customer satisfaction. We bring innovative designs, superlative quality, and cutting-edge technology.
            </p>
            <div className="hero-buttons">
              <a
                href="#projects"
                className="btn btn-primary btn-large"
              >
                Our Projects
              </a>
              <a
                href="#contact"
                className="btn btn-secondary btn-large"
              >
                Get in Touch
              </a>
            </div>
          </motion.div>
        </div>
        <motion.div
          className="scroll-indicator"
          animate={{ y: [0, 10, 0] }}
          transition={{ duration: 2, repeat: Infinity }}
        >
          <ChevronDown color="white" size={32} />
        </motion.div>
      </header>

      {/* About Section */}
      <section id="welcome" className="welcome py-100">
        <div className="container section-grid">
          <motion.div className="content-left" {...fadeIn}>
            <span className="subtitle">About Alray</span>
            <h2 className="section-title">Crafting Excellence Since Inception</h2>
            <p>Alray Associates promises to deliver top-notch craftsmanship in the new construction and remodeling
              industry. We are committed to meeting the changing needs of our customers through every step of the
              design and building process.</p>
            <p>Supported by extensive knowledge and vast experience, our skilled workforce is committed to the
              timely completion of every project undertaken without compromising on quality, safety, and
              environment.</p>
            <div className="stats-container">
              <Counter value="100" suffix="%" title="Satisfaction" />
              <Counter value="15" suffix="+" title="Modern Projects" />
              <Counter value="100" suffix="%" title="On-Time Delivery" />
            </div>
          </motion.div>
          <motion.div
            className="content-right image-card"
            initial={{ opacity: 0, x: 50 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8 }}
          >
            <div className="image-inner glass-effect">
              <img src="/images/mangadu.jpg" alt="Alray Associates Mangadu Project" />
            </div>
          </motion.div>
        </div>
      </section>

      {/* Vision & Mission */}
      <section id="vision-mission" className="vision-mission bg-premium-dark py-100 text-white">
        <div className="container section-grid-3">
          {[
            {
              title: 'Our Vision',
              icon: <Building2 />,
              text: 'To be a world-class infrastructure construction and Real Estate Development company committed to total customer satisfaction.'
            },
            {
              title: 'Our Mission',
              icon: <ShieldCheck />,
              text: 'Our mission is to deliver promises with strong adherence to ethical business practices. Our pledge is to establish lasting relationships.'
            },
            {
              title: 'Our Strategic Excellence',
              icon: <Layout />,
              text: 'We provide value-added construction services to our customers by creating a successful partnership throughout the process.',
              highlight: true
            },
          ].map((card, idx) => (
            <motion.div
              key={idx}
              className={`card glass-card ${card.highlight ? 'highlight-card' : ''}`}
              {...fadeIn}
              transition={{ delay: idx * 0.2 }}
            >
              <div className="icon-wrap">{card.icon}</div>
              <h3>{card.title}</h3>
              <p>{card.text}</p>
            </motion.div>
          ))}
        </div>
      </section>

      {/* Process Section */}
      <section id="process" className="process py-100 bg-light">
        <div className="container">
          <motion.div className="text-center section-header" {...fadeIn}>
            <span className="subtitle">How We Work</span>
            <h2 className="section-title">Our Transparent Process</h2>
            <div className="title-underline"></div>
          </motion.div>

          <div className="process-grid">
            {[
              { icon: <Coffee />, title: 'Consultation', text: 'Meeting to understand your needs, vision, and project budget.' },
              { icon: <Layout />, title: 'Design & Planning', text: 'Creating architectural blueprints and detailed floor plans.' },
              { icon: <PenTool />, title: 'Estimation', text: 'Precise cost analysis and material selection for transparency.' },
              { icon: <Truck />, title: 'Construction', text: 'On-site execution with rigorous quality control at every step.' },
              { icon: <CheckCircle2 />, title: 'Handover', text: 'Final inspection and delivering your dream project on time.' },
            ].map((step, idx) => (
              <motion.div
                key={idx}
                className="process-step"
                {...fadeIn}
                transition={{ delay: idx * 0.2 }}
              >
                <div className="step-number">{idx + 1}</div>
                <div className="text-primary mb-15" style={{ color: 'var(--color-primary)' }}>{step.icon}</div>
                <h4>{step.title}</h4>
                <p>{step.text}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Services Section */}
      <section id="services" className="services py-100">
        <div className="container">
          <motion.div className="text-center section-header" {...fadeIn}>
            <span className="subtitle">What We Do</span>
            <h2 className="section-title">Our Premium Services</h2>
            <div className="title-underline"></div>
          </motion.div>

          <div className="services-grid">
            {[
              { icon: <Hammer />, title: 'Custom Home Building', text: 'Building your dream home from the ground up with precision and high-quality craftsmanship.' },
              { icon: <Building2 />, title: 'Residential Remodeling', text: 'Transforming your current space into a modern, functional, and aesthetically pleasing environment.' },
              { icon: <Layout />, title: 'Design-Build Projects', text: 'A streamlined approach offering both design and construction services under a single contract.' },
              { icon: <MapIcon />, title: 'Site & Home Planning', text: 'Comprehensive site planning and home design, ensuring optimal use of space and resources.' },
              { icon: <ClipboardList />, title: 'Construction Management', text: 'Professional oversight of your construction project to ensure timely delivery and budget adherence.' },
              { icon: <ShieldCheck />, title: 'Waterproofing & Insulation', text: 'Expert waterproofing and insulation to protect your investment from the elements.' },
            ].map((service, idx) => (
              <motion.div
                key={idx}
                className="service-card"
                {...fadeIn}
                transition={{ delay: (idx % 3) * 0.1 }}
              >
                <div className="service-icon text-primary" style={{ fontSize: '2.5rem', marginBottom: '1rem', color: 'var(--color-primary)' }}>
                  {service.icon}
                </div>
                <h3>{service.title}</h3>
                <p>{service.text}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Projects Section */}
      <section id="projects" className="projects bg-light py-100">
        <div className="container">
          <motion.div className="text-center section-header" {...fadeIn}>
            <span className="subtitle">Our Portfolio</span>
            <h2 className="section-title">Featured Projects</h2>
            <div className="title-underline"></div>
          </motion.div>

          <div className="projects-grid">
            {[
              {
                title: 'Alray Heritage Residency',
                desc: 'A magnificent Stilt + 3 Floors premium apartment featuring RCC framed structure, cool roof tiles, and top-class amenities.',
                img: '/images/mugalivakkam.jpg',
                features: ['Pile Foundation', 'Premium Vitrified Tiles', 'Teak Wood Doors', 'Passenger Lift']
              },
              {
                title: 'Alray Heritage Garden',
                desc: 'A sophisticated residential building featuring a harmonious blend of brown and white tones, designed for comfortable family living.',
                img: '/images/alray_heritage_garden.jpg',
                features: ['Stilt + 3 Floors', 'Elegant Balconies', 'Modern Facade', 'Quality Construction']
              },
              {
                title: 'Alray Onyx Heights',
                desc: 'A striking contemporary multi-story building with a bold dark brown and white palette, offering a premium urban lifestyle.',
                img: '/images/alray_onyx_heights.jpg',
                features: ['Bold Design', 'Floor-to-Ceiling Windows', 'Premium Aluminum Joinery', 'Luxurious Entrance']
              },
              {
                title: 'Alray Signature Villas',
                desc: 'A sprawling multi-story residential building carefully designed with precise floor plans. Crafted for elegant living.',
                img: '/images/mangadu.jpg',
                features: ['Detailed Floor Plans', 'High-quality Finish', 'Spacious Living Areas']
              },
              {
                title: 'Alray Modern Residence',
                desc: 'A contemporary 3-story residential building featuring modern architectural aesthetics and premium finishes.',
                img: '/images/alray_modern_residence.jpg',
                features: ['Modern Facade', '3-Story Design', 'Premium Materials', 'Optimized Space']
              },
              {
                title: 'Alray Commercial Hub',
                desc: 'A state-of-the-art multi-story commercial and residential complex featuring innovative design and modern amenities.',
                img: '/images/alray_commercial_complex.jpg',
                features: ['Innovative Architecture', 'Mixed-use Spaces', 'Glass Balconies', 'Modern Amenities']
              }
            ].map((project, idx) => (
              <motion.div
                key={idx}
                className="project-card"
                {...fadeIn}
                transition={{ delay: idx * 0.3 }}
              >
                <div className="project-image">
                  <img src={project.img} alt={project.title} />
                </div>
                <div className="project-content">
                  <h3>{project.title}</h3>
                  <p className="description">{project.desc}</p>
                  <ul className="project-features">
                    {project.features.map(f => <li key={f}>{f}</li>)}
                  </ul>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Leadership */}
      <section id="leadership" className="leadership py-100">
        <div className="container">
          <motion.div className="text-center section-header" {...fadeIn}>
            <span className="subtitle">Our People</span>
            <h2 className="section-title">Leadership</h2>
            <div className="title-underline"></div>
          </motion.div>

          <div className="team-grid">
            {[
              { name: 'H. Abdul Kader', role: 'Managing Director' },
              { name: 'H. Abdul Razack', role: 'Director - Technical' },
              { name: 'M.A. Noor Mohamed', role: 'Director - Marketing' },
            ].map((member, idx) => (
              <motion.div
                key={idx}
                className="team-member"
                {...fadeIn}
                transition={{ delay: idx * 0.2 }}
              >
                <div className="member-info border-accent">
                  <h4>{member.name}</h4>
                  <p className="role">{member.role}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Contact Section */}
      <section id="contact" className="contact py-100 bg-premium-navy text-white">
        <div className="container section-grid">
          <motion.div className="contact-info" {...fadeIn}>
            <h2 className="section-title text-white">Get in Touch</h2>
            <div className="title-underline left"></div>
            <p className="mb-30">Ready to start your next premium residential or commercial project? Contact us today to discuss your vision.</p>

            <div className="contact-details">
              {[
                { icon: <MapPin />, title: 'Corporate Office', content: <>ALRAY ASSOCIATES,<br />1/1245, 1st Floor, West Main Road,<br />Kumudham Nagar, Mugalivakkam,<br />Chennai - 600 125.</> },
                { icon: <Phone />, title: 'Phone', content: '+91 86670 11700 / +91 98413 24123' },
                { icon: <Mail />, title: 'Email', content: 'alrayassociates@gmail.com' },
                { icon: <MessageCircle />, title: 'WhatsApp', content: '+91 86670 11700' },
              ].map((item, idx) => (
                <div key={idx} className="contact-item">
                  <div className="icon">{item.icon}</div>
                  <div>
                    <h4>{item.title}</h4>
                    <p>{item.content}</p>
                  </div>
                </div>
              ))}
            </div>
          </motion.div>

          <motion.div
            className={`contact-form-container ${formSubmitted ? 'submitted' : ''}`}
            initial={{ opacity: 0, scale: 0.95 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            transition={{ duration: 0.8 }}
          >
            {formSubmitted ? (
              <div className="success-message glass-form">
                <div className="success-icon">
                  <CheckCircle2 size={64} className="text-accent" />
                </div>
                <h3>Digital Inquiry Sent!</h3>
                <p>Your record has been automatically synced with our team's management system. We will review your project details and reach out to you shortly.</p>
                <button
                  onClick={() => setFormSubmitted(false)}
                  className="btn btn-primary"
                  style={{ marginTop: '20px' }}
                >
                  Send Another Message
                </button>
              </div>
            ) : (
              <form className="glass-form" onSubmit={handleSubmit}>
                <h3>Send an Inquiry</h3>
                <div className="form-group">
                  <input
                    type="text"
                    placeholder="Your Name"
                    required
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <input
                    type="email"
                    placeholder="Your Email"
                    required
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <input
                    type="tel"
                    placeholder="Phone Number"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <select
                    required
                    value={formData.service}
                    onChange={(e) => setFormData({ ...formData, service: e.target.value })}
                    className="form-select"
                  >
                    <option value="" disabled>Select Service Interested In</option>
                    <option value="Custom Home Building">Custom Home Building</option>
                    <option value="Residential Remodeling">Residential Remodeling</option>
                    <option value="Design-Build Projects">Design-Build Projects</option>
                    <option value="Site & Home Planning">Site & Home Planning</option>
                    <option value="Construction Management">Construction Management</option>
                    <option value="Waterproofing & Insulation">Waterproofing & Insulation</option>
                    <option value="Other">Other Inquiry</option>
                  </select>
                </div>
                <div className="form-group">
                  <textarea
                    rows="5"
                    placeholder="Project Details or Message"
                    required
                    value={formData.message}
                    onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                  ></textarea>
                </div>
                <button type="submit" className="btn btn-primary btn-block" disabled={formLoading}>
                  {formLoading ? 'Sending...' : 'Send Message'}
                  <ArrowRight size={18} style={{ marginLeft: '8px' }} />
                </button>
              </form>
            )}
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="footer py-50">
        <div className="container footer-content">
          <div className="footer-brand">
            <Logo light />
            <p>Building your dreams into reality with unmatched craftsmanship and high-quality materials.</p>
          </div>
          <div className="footer-links">
            <h3>Quick Links</h3>
            <ul>
              {navLinks.map(link => (
                <li key={link.name}><a href={link.href}>{link.name}</a></li>
              ))}
            </ul>
          </div>
        </div>
        <div className="footer-bottom">
          <p>&copy; 2026 Alray Associates. All Rights Reserved.</p>
        </div>
      </footer>
    </div>
  );
}

export default App;
